function ChangePosition(obj, btobj, Ticker, Pct, PriceField)
% ��һֻ��Ʊ���е���
% obj: Account���ʵ��
% btobj: BackTest���ʵ��
% Ticker: ��Ҫ���ֵı���
% Pct: ���ֺ�ı������������С��1e-6, �������Ʊ��
% PriceField: ����ʹ�ü۸�, ����Ĭ��Ϊ'Close'
% 
% �ú�����ɶԹ�ƱTicker�ĵ��֣����ֺ�ı���ΪPct

Slippage = btobj.Slippage;
SellCommission = btobj.SellComission;
BuyCommission = btobj.BuyComission;


StockID = find(strcmp(obj.StockPool.Tickers, Ticker));
BarData = btobj.Data.GetBar(Ticker);
Price = BarData.(PriceField);
PreClose = BarData.PreClose;

% Step1: �ж��Ƿ���Ҫɾ����Ʊ
if Pct < 1e-6 && ~isempty(StockID)
    Volume = obj.StockPool.Volume(StockID);
    % �ж��Ƿ��ڵ�ͣ��������ȥ
    if Price < PreClose * (1 - 0.095)
        obj.AddRemainedStocksToSell(Ticker, Volume);
    else
        dAsset = Volume * Price * (1 - Slippage - SellComission);
        obj.StockPool.Volume(StockID) = 0;
        obj.StockPool.Tickers{StockID} = '';
        obj.Cash = obj.Cash + dAsset;
    end
end

% Step2: �ж��Ƿ���Ҫ��ӹ�Ʊ
if Pct > 1e-6 && isempty(StockID)
    % ֻ����100��Ϊ��λ��������
    % Pct������Volume0
    Volume0 = round(obj.Asset * Pct / Price / (1 + Slippage + BuyComission) / 100) * 100;
    % ���е��ֽ������Volume1
    Volume1 = floor(obj.Cash / (Price / (1 + Slippage + BuyComission) / 100)) * 100;
    Volume = min(Volume0, Volume1);
    if Volume > 0
    % �ж��Ƿ�����ͣ���򲻽���
        if Price > PreClose * (1 + 0.095)
            obj.AddRemainedStocksToBuy(Ticker, Volume);
        else
            dAsset = Volume * Price * ( 1 + Slippage + BuyComission);
            obj.Cash = obj.Cash - dAsset;
            InsertID = find(strcmp(obj.StockPool.Tickers, ''), 1);
            obj.StockPool.Tickers{InsertID} = Ticker;
            obj.StockPool.Volume(InsertID) = Volume;
        end
    end
end

% Step3: �ж��Ƿ���Ҫ�������в�λ
if Pct > 1e-6 && ~isempty(StockID)
    Volume0 = obj.StockPool.Volume(StockID);
    Volume1 = round(obj.Asset * Pct / Price / (1 + Slippage + BuyComission) / 100) * 100;
    if Volume0 > Volume1
        dVolume = Volume0 - Volume1;
        if Price < PreClose * (1 - 0.095)
            obj.AddRemainedStocksToSell(Ticker, dVolume);
        else
            dAsset = dVolume * Price * (1 - Slippage - SellComission);
            obj.StockPool.Volume(StockID) = Volume1;
            obj.Cash = obj.Cash + dAsset;
        end
    elseif Volume0 < Volume1
        dVolume0 = Volume1 - Volume0;
        dVolume1 = floor(obj.Cash / Price / (1 + Slippage + BuyComission) / 100) * 100;
        dVolume = min(dVolume0, dVolume1);
        if dVolume > 0
            if Price > PreClose * (1 + 0.095)
                obj.AddRemainedStocksToBuy(Ticker, dVolume);
            else
                dAsset = dVolume * Price * (1 + Slippage + BuyComission);
                obj.StockPool.Volume(StockID) = Volume0 + dVolume;
                obj.Cash = obj.Cash - dAsset;
            end
        end
    end
end

end
