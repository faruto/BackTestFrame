function ChangePosition(obj, btobj, Ticker, Pct, PriceField)
% ��һֻ��Ʊ���е���
% obj: Account���ʵ��
% btobj: BackTest���ʵ��
% Ticker: ��Ҫ���ֵı���
% Pct: ���ֺ�ı������������С��1e-6, �������Ʊ��
% PriceField: ����ʹ�ü۸�, ����Ĭ��Ϊ'Close'
% 
% �ú�����ɶԹ�ƱTicker�ĵ��֣����ֺ�ı���ΪPct

if length(Ticker) > 1
    error('ChangePosition����ֻ�ܶ�һֻ��Ʊ���е���!');
end

Slippage = btobj.Slippage;
SellCommission = btobj.SellCommission;
BuyCommission = btobj.BuyCommission;


StockID = find(strcmp(obj.StockPool.Tickers, Ticker));
BarData = btobj.Data.GetBar(Ticker);
Price = BarData.(PriceField);
PreClose = BarData.PreClose;

% Step1: �������гֲ�
if ~isempty(StockID)
    Volume0 = obj.StockPool.Volume(StockID);
    Volume1 = round(obj.Asset * Pct / Price / (1 + Slippage + 0.5*(BuyCommission + SellComission)) / 100) * 100;
    if Volume0 > Volume1
        dVolume = Volume0 - Volume1;
        if Price < PreClose * (1 - 0.095)
            obj.AddRemainedStocksToSell(Ticker, dVolume);
        else
            dAsset = dVolume * Price * (1 - Slippage - SellCommission);
            obj.StockPool.Volume(StockID) = Volume1;
            obj.Cash = obj.Cash + dAsset;
            % ����˲���ʲ���ֵ��ˮ�Ĳ��ּ�Ϊ�����Ѻͻ���
            obj.Asset = obj.Asset - dVolume * Price * (Slippage + SellCommission);
            % ��ոù�Ʊ
            if Volume1 == 0
                obj.StockPool.Ticker{StockID} = '';
            end
        end
    elseif Volume0 < Volume1
        dVolume0 = Volume1 - Volume0;
        dVolume1 = floor(obj.Cash / Price / (1 + Slippage + BuyCommission) / 100) * 100;
        dVolume = min(dVolume0, dVolume1);
        if dVolume > 0
            if Price > PreClose * (1 + 0.095)
                obj.AddRemainedStocksToBuy(Ticker, dVolume);
            else
                dAsset = dVolume * Price * (1 + Slippage + BuyCommission);
                obj.StockPool.Volume(StockID) = Volume0 + dVolume;
                obj.Cash = obj.Cash - dAsset;
                obj.Asset = obj.Asset - dVolume * Price * (Slippage + BuyCommission);
            end
        end
    end
% Step2: ��ӹ�Ʊ
else
    % Pct������Volume0
    Volume0 = round(obj.Asset * Pct / Price / (1 + Slippage + BuyCommission) / 100) * 100;
    % ���е��ֽ������Volume1
    Volume1 = floor(obj.Cash / (Price / (1 + Slippage + BuyCommission) / 100)) * 100;
    Volume = min(Volume0, Volume1);
    if Volume > 0
    % �ж��Ƿ�����ͣ���򲻽���
        if Price > PreClose * (1 + 0.095)
            obj.AddRemainedStocksToBuy(Ticker, Volume);
        else
            dAsset = Volume * Price * ( 1 + Slippage + BuyCommission);
            obj.Cash = obj.Cash - dAsset;
            InsertID = find(strcmp(obj.StockPool.Tickers, ''), 1);
            obj.StockPool.Ticker{InsertID} = Ticker;
            obj.StockPool.Volume(InsertID) = Volume;
            obj.Asset = obj.Asset - Volume * Price * (Slippage + BuyCommission);
        end
    end
end

end
