function ChangeStockPool(obj, btobj, Tickers, Pcts, PriceField)
% ���¹�Ʊ��
% obj: Account���ʵ��
% btobj: BackTestFrame��ʵ��
% Tickers: cell ��ʾ�ѹ�Ʊ�صĹ�Ʊ����ΪTickers
% Pcts: Tickers�İٷֱȣ���������sum(Pcts)<=1
% PriceField: ����ʹ�õĹɼ۰ٷֱȣ����������������е�field, Ĭ��Ϊ'Close'
%
% �ú�����ɵ��֣���ԭ�ȵĹ�Ʊ���еĹ�Ʊ����ΪTickers������ΪPcts

if sum(Pcts) > 1
    error('���ֵ����й�Ʊռ�ȳ���100%!');
end

Slippage = btobj.Slippage;
SellCommission = btobj.SellCommission;
BuyCommission = btobj.BuyCommission;

% ChangeTickers��ʾ��Ҫ�ڹ�Ʊ���е����Ĺ�Ʊ
[ChangeTickers, ChangeID0, ChangeID1] = intersect(obj.StockPool.Ticker, Tickers);
% AddTickers��ʾ��Ҫ��ӵ���Ʊ���еĹ�Ʊ
[AddTickers, AddID0] = setdiff(Tickers, ChangeTickers);

% ��ý���Tickers��bar����
BarData = btobj.Data.GetBar(Tickers);

% Step1: �������гֲ�
ChangeBars = btobj.Data.SelectBar(BarData, ChangeID1);
Prices = ChangeBars.(PriceField);
PreCloses = ChangeBars.PreClose;
for i = 1:length(ChangeTickers)
    Ticker = ChangeTickers{i};
    Price = Prices(i);
    PreClose = PreCloses(i);
    
    i0 = ChangeID0(i);
    i1 = ChangeID1(i);
    Pct = Pcts(i1);
    Volume0 = obj.Stockpool.Volume(i0);
    Volume1 = round(obj.Asset * Pct / Price / (1 + Slippage + 0.5*(BuyCommission + SellCommission)) / 100) * 100;
    if Volume0 > Volume1
        dVolume = Volume0 - Volume1;
        if Price(i) < PreClose * (1 - 0.095)
            obj.AddRemainedStocksToSell(Ticker, dVolume);
        else
            dAsset = dVolume * Price * (1 - Slippage - SellCommission);
            obj.Cash = obj.Cash + dAsset;
            obj.Asset = obj.Asset - dVolume * Price * (Slippage + SellCommission);
            obj.StockPool.Volume(i0) = Volume1;
            if Volume1 == 0
                obj.StockPool.Ticker{i0} = '';
            end
        end
    elseif Volume0 < Volume1
        dVolume0 = Volume1 - Volume0;
        dVolume1 = floor(obj.Cash / Price / (1 + Slippage + BuyCommission) / 100) * 100;
        dVolume = min(dVolume0, dVolume1);
        if Price(i) > PreClose * (1 - 0.095)
            obj.AddRemainedStocksToBuy(Ticker, dVolume);
        else
            dAsset = dVolume * Price * (1 + Slippage + BuyCommission);
            obj.Cash = obj.Cash - dAsset;
            obj.Asset = obj.Asset - Price * (Slippage + BuyCommission);
            obj.StockPool.Volume(i0) = Volume0 + dVolume;
        end
    end
end

% Step2: ��ӹ�Ʊ
AddBars = btobj.Data.SelectBar(BarData, AddID0);
Prices = AddBars.(PriceField);
PreCloses = AddBars.PreClose;
for i = 1:length(AddTickers)
    Ticker = AddTickers{i};
    Price = Prices(i);
    PreClose = PreCloses(i);
    i0 = AddID0(i);
    Pct = Pcts(i0);
    Volume0 = round(obj.Asset * Pct / Price / (1 + Slippage + BuyCommission) / 100) * 100;
    Volume1 = floor(obj.Cash / (Price / (1 + Slippage + BuyCommission) / 100)) * 100;
    Volume = min(Volume0, Volume1);
    if Volume > 0
        if Price(i) > PreClose * (1 + 0.095)
            obj.AddRemainedStocksToBuy(Ticker, Volume, 1);
        else
            dAsset = Volume * Price * (1 + Slippage + BuyCommission);
            obj.Cash = obj.Cash - dAsset;
            obj.Asset = obj.Asset - Price * (Slippage + BuyCommission);
            InsertID = find(strcmp(obj.StockPool.Ticker, ''), 1);
            obj.StockPool.Ticker{InsertID} = Ticker;
            obj.StockPool.Volume(InsertID) = Volume;
        end
    end
end

end
