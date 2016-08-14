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
SellCommission = btobj.SellComission;
BuyCommission = btobj.BuyComission;


Index = Pcts < 1e-6;
DeleteTickers = Tickers(Index);
[DeleteTickers, DeleteID0, DeleteID1] = intersect(obj.StockPool.Tickers, DelteTickers); 
TickersTmp = Tickers(~Index); 
[ChangeTickers, ChangeID0, ChangeID1] = intersect(obj.StockPool.Tickers, TickersTmp);
AddTickers = setdiff(TickersTmp, ChangeTickers);

N = length(Tickers);
BarData = btobj.Data.GetBar(Tickers);

% Step1: ɾ����Ҫɾ���Ĺ�Ʊ
DeleteBar = btobj.Data.SelectBar(BarData, Index);
DeleteBar = btobj.Data.SelectBar(DeleteBar, DeleteID1);
Price = DeleteBar.(PriceField);
PreClose = DeleteBar.PreClose;
for i = 1:length(DeleteTickers)
    i0 = DeleteID0(i);
    Ticker = DeleteTickers{i};
    % ��ͣ������ȥ
    if Price(i1) < (1 - 0.095) * PreClose(i)
        obj.AddRemainedStocksToSell(Ticker);
        continue;
    end
    % ������Ʊ
    dAsset = obj.StockPool.Volume(i0) * Price(i) * (1 - Slippage - SellComission);
    obj.StockAsset = obj.StockAsset - dAsset;
    obj.Cash = obj.Cash + dAsset;
end
obj.StockPool.Volume(DeleteID0) = 0;
obj.StockPool.Tickers(DeleteID0) = repmat('', length(DeleteID0), 1);
obj.StockPool.CostPrice(DeleteID0) = 0;

obj.Asset = obj.StockAsset + obj.Cash;

% Step2: �������гֲ�
ChangeBar = btobj.Data.SelectBar(BarData, ~Index);
ChangeBar = btobj.data.SelectBar(ChangeBar, ChangeID1);
ChangePcts = Pcts(~Index);
ChangePcts = ChangePcts(ChangeID1);
Price = ChangeBar.(PriceField);
PreClose = ChangeBar.PreClose;
for i = 1:length(ChangeTickers)
    i0 = ChangeID0(i);
    Ticker = ChangeTickers{i};
    Pct = ChangePcts(i);
    Pct0 = obj.StockPool.Volume(i0) * Price(i) / obj.Asset;
    % ����������ȹ�С���������
    if abs(Pct0 - Pct) < obj.ChangePositionThreshold
        continue;
    end
    % ����
    if Pct0 > Pct
        
    else
    end
end
end
