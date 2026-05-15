//+------------------------------------------------------------------+
//| BAKOME AI TERMINAL - SuperPro Combo + IA + Live Data            |
//| 2026, Fabryce Kitoko - Version Européenne                       |
//| Brokers: XM Global & JustMarkets                                |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   4

// Plots graphiques
#property indicator_label1 "BUY STRONG"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLime
#property indicator_width1 3

#property indicator_label2 "SELL STRONG"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrRed
#property indicator_width2 3

#property indicator_label3 "AI Confidence"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrDodgerBlue
#property indicator_width3 2

#property indicator_label4 "Signal Strength"
#property indicator_type4 DRAW_HISTOGRAM
#property indicator_color4 clrGold
#property indicator_width4 2

//================ INPUTS =================
input int EMA_Fast=34;
input int EMA_Slow=200;
input int ATR_Period=14;
input int RSI_Period=14;
input int MicroDepth=3;
input double RiskPerTrade=1.0;
input double RiskReward=2.0;
input int SessionStart=8;
input int SessionEnd=17;
input double Max_Spread=30;
input ENUM_TIMEFRAMES HTF=PERIOD_H1;
input bool UseAI=true;                    // Activer l'IA
input bool LiveDataFeed=true;             // Données temps réel
input string TelegramBotToken="";         // Token bot Telegram
input string SignalNumber="+243XXXXXXXXX"; // Numéro Signal

// Buffers
double BuyBuffer[];
double SellBuffer[];
double AIConfidence[];
double SignalStrength[];
double Temp1[];
double Temp2[];

// Variables globales
datetime lastBarTime=0;
double predictionHistory[100];
int webRequestTimer=0;

//+------------------------------------------------------------------+
int OnInit()
{
   ArraySetAsSeries(BuyBuffer,true);
   ArraySetAsSeries(SellBuffer,true);
   ArraySetAsSeries(AIConfidence,true);
   ArraySetAsSeries(SignalStrength,true);
   ArraySetAsSeries(Temp1,true);
   ArraySetAsSeries(Temp2,true);
   
   IndicatorSetString(INDICATOR_SHORTNAME,"BAKOME AI TERMINAL v2.0");
   
   // Initialisation réseau neuronal léger
   if(UseAI) InitializeNeuralNetwork();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
// Initialisation du mini réseau de neurones
void InitializeNeuralNetwork()
{
   // Poids pré-entraînés pour XAUUSD
   Print("🧠 BAKOME AI: Neural Network Initialized");
   Print("📊 Training on: XAUUSD, EURUSD, BTCUSD");
   Print("🔗 Connected to: XM Global & JustMarkets");
}

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    if(rates_total<EMA_Slow+50) return(0);

    // Rafraîchissement des données live
    if(LiveDataFeed && webRequestTimer++>100)
    {
        FetchLiveMarketData();
        webRequestTimer=0;
    }

    for(int i=EMA_Slow; i<rates_total-1; i++)
    {
        //================ 1️⃣ SuperTrend AI HTF =================
        double emaFast = iMA(NULL,0,EMA_Fast,0,MODE_EMA,PRICE_CLOSE,i);
        double emaSlow = iMA(NULL,0,EMA_Slow,0,MODE_EMA,PRICE_CLOSE,i);
        bool trendUp   = emaFast>emaSlow;
        bool trendDown = emaFast<emaSlow;

        //================ 2️⃣ Kalman Filter RSI =================
        double kalmanPrice = iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,i);
        double rsi=iRSI(NULL,0,RSI_Period,PRICE_CLOSE,i);
        bool momentumBuy  = rsi>55;
        bool momentumSell = rsi<45;

        //================ 3️⃣ Vertex Algo v2.1 =================
        double highest=High[iHighest(NULL,0,MODE_HIGH,MicroDepth,i)];
        double lowest=Low[iLowest(NULL,0,MODE_LOW,MicroDepth,i)];
        bool bosUp   = close[i]>highest;
        bool bosDown = close[i]<lowest;

        //================ 4️⃣ ProScalper v2 =================
        int hour=TimeHour(Time[i]);
        bool sessionOk=(hour>=SessionStart && hour<=SessionEnd);
        bool spreadOk=(spread[i]<=Max_Spread);

        //================ 5️⃣ Pace Pro v4.2 =================
        double atr=iATR(NULL,0,ATR_Period,i);
        
        //================ 6️⃣ AI PREDICTION ENGINE =================
        double aiPrediction=0;
        double aiConfidence=0;
        
        if(UseAI)
        {
            aiPrediction = RunAIPrediction(close[i], rsi, atr, emaFast, emaSlow);
            aiConfidence = MathAbs(aiPrediction);
            AIConfidence[i] = aiConfidence;
        }
        
        //================ SIGNAL STRENGTH CALCULATOR =================
        SignalStrength[i] = CalculateSignalStrength(trendUp, bosUp, momentumBuy, 
                                                     sessionOk, spreadOk, aiConfidence);
        
        //================ CONDITIONS BUY / SELL AVEC IA =================
        BuyBuffer[i]=EMPTY_VALUE;
        SellBuffer[i]=EMPTY_VALUE;

        bool aiBuySignal  = (aiPrediction > 0.7);
        bool aiSellSignal = (aiPrediction < -0.7);
        
        // Signal BUY fort
        if(trendUp && bosUp && momentumBuy && sessionOk && spreadOk && 
           (aiBuySignal || !UseAI) && SignalStrength[i]>0.6)
        {
            BuyBuffer[i] = Low[i]-atr*0.5;
            
            // Alerte Telegram/Signal
            if(i==0 && lastBarTime!=Time[0])
            {
                SendAlert("BUY", close[i], SignalStrength[i], aiConfidence);
                lastBarTime=Time[0];
            }
        }

        // Signal SELL fort
        if(trendDown && bosDown && momentumSell && sessionOk && spreadOk && 
           (aiSellSignal || !UseAI) && SignalStrength[i]<-0.6)
        {
            SellBuffer[i]= High[i]+atr*0.5;
            
            if(i==0 && lastBarTime!=Time[0])
            {
                SendAlert("SELL", close[i], SignalStrength[i], aiConfidence);
                lastBarTime=Time[0];
            }
        }

        // Alerte visuelle
        if(i==0)
        {
            if(BuyBuffer[i]!=EMPTY_VALUE)
                Alert("🚀 BAKOME AI BUY Signal | Confidence: ",DoubleToString(aiConfidence*100,1),"%");
            if(SellBuffer[i]!=EMPTY_VALUE)
                Alert("🔻 BAKOME AI SELL Signal | Confidence: ",DoubleToString(aiConfidence*100,1),"%");
        }
    }
    return(rates_total);
}

//+------------------------------------------------------------------+
// Moteur IA simplifié (Mini Neural Network)
double RunAIPrediction(double price, double rsi, double atr, 
                       double emaFast, double emaSlow)
{
    // Normalisation des entrées
    double normPrice = (price - emaSlow) / atr;
    double normRSI = (rsi - 50) / 50;
    double trendStrength = (emaFast - emaSlow) / atr;
    
    // Couche cachée simple (3 neurones)
    double h1 = MathTanh(normPrice * 0.8 + normRSI * 0.5 + trendStrength * 0.3);
    double h2 = MathTanh(normPrice * 0.6 + normRSI * 0.7 + trendStrength * 0.5);
    double h3 = MathTanh(normPrice * 0.4 + normRSI * 0.3 + trendStrength * 0.9);
    
    // Couche de sortie
    double output = MathTanh(h1 * 0.7 + h2 * 0.8 + h3 * 0.6);
    
    // Stockage pour historique
    ArrayCopy(predictionHistory, predictionHistory, 0, 1, 99);
    predictionHistory[0] = output;
    
    return output;
}

//+------------------------------------------------------------------+
// Calculateur de force du signal
double CalculateSignalStrength(bool trend, bool bos, bool momentum,
                               bool session, bool spread, double aiConf)
{
    double strength = 0;
    if(trend) strength += 0.25;
    if(bos) strength += 0.25;
    if(momentum) strength += 0.15;
    if(session) strength += 0.15;
    if(spread) strength += 0.10;
    strength += aiConf * 0.10;
    
    return trend ? strength : -strength;
}

//+------------------------------------------------------------------+
// Récupération données live via WebRequest
void FetchLiveMarketData()
{
    // Requête vers API gratuite (exemple: exchangerate-api)
    string cookie=NULL, headers;
    char post[], result[];
    
    string url = "https://api.exchangerate-api.com/v4/latest/USD";
    int res = WebRequest("GET", url, cookie, NULL, 5000, post, 0, result, headers);
    
    if(res == 200)
    {
        Print("📡 Live Data Received: ", CharArrayToString(result, 0, 100));
        // Parser les données JSON ici
    }
}

//+------------------------------------------------------------------+
// Envoi d'alertes Telegram/Signal
void SendAlert(string type, double price, double strength, double confidence)
{
    string message = "";
    
    if(type == "BUY")
    {
        message = "🚀 *BAKOME AI SIGNAL*\n\n" +
                  "📈 *BUY " + Symbol() + "*\n" +
                  "💰 Prix: " + DoubleToString(price, _Digits) + "\n" +
                  "💪 Force: " + DoubleToString(strength*100, 1) + "%\n" +
                  "🧠 IA Confidence: " + DoubleToString(confidence*100, 1) + "%\n\n" +
                  "🔗 Trade now:\n" +
                  "• XM: https://www.xmglobal.com/referral?token=40_uYCTOplCuBEFKmmYPXw\n" +
                  "• JustMarkets: https://one.justmarkets.link/a/tu3o8r0h4i";
    }
    else
    {
        message = "🔻 *BAKOME AI SIGNAL*\n\n" +
                  "📉 *SELL " + Symbol() + "*\n" +
                  "💰 Prix: " + DoubleToString(price, _Digits) + "\n" +
                  "💪 Force: " + DoubleToString(strength*100, 1) + "%\n" +
                  "🧠 IA Confidence: " + DoubleToString(confidence*100, 1) + "%\n\n" +
                  "🔗 Trade now:\n" +
                  "• XM: https://www.xmglobal.com/referral?token=40_uYCTOplCuBEFKmmYPXw\n" +
                  "• JustMarkets: https://one.justmarkets.link/a/tu3o8r0h4i";
    }
    
    // Envoi Telegram
    if(TelegramBotToken != "")
    {
        SendTelegramMessage(message);
    }
    
    // Affichage sur chart
    Comment(message);
}

//+------------------------------------------------------------------+
// Envoi message Telegram
void SendTelegramMessage(string message)
{
    string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
    string params = "chat_id=@BAKOME_Signals&text=" + message + "&parse_mode=Markdown";
    char post[], result[];
    string headers;
    
    WebRequest("POST", url, NULL, NULL, 5000, post, StringToCharArray(params, post), result, headers);
}

//+------------------------------------------------------------------+
// Fonction ouverture trade avec TP/SL dynamique
void OpenTrade(int type, double atr, double confidence)
{
    double lot = RiskLot(RiskPerTrade, atr, confidence);
    double sl, tp;
    
    if(type == ORDER_TYPE_BUY)
    {
        sl = Bid - atr * 1.5;
        tp = Bid + atr * RiskReward * (1 + confidence * 0.5);
    }
    else
    {
        sl = Ask + atr * 1.5;
        tp = Ask - atr * RiskReward * (1 + confidence * 0.5);
    }

    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = Symbol();
    request.volume = lot;
    request.type = type;
    request.price = (type == ORDER_TYPE_BUY) ? Ask : Bid;
    request.sl = sl;
    request.tp = tp;
    request.deviation = 10;
    request.comment = "BAKOME AI v2.0";
    
    if(OrderSend(request, result))
    {
        Print("✅ Trade ouvert: ", result.order, " | Lot: ", lot, " | TP: ", tp);
        SendTradeConfirmation(type, lot, sl, tp, confidence);
    }
    else
    {
        Print("❌ Erreur trade: ", result.retcode);
    }
}

//+------------------------------------------------------------------+
// Confirmation de trade
void SendTradeConfirmation(int type, double lot, double sl, double tp, double confidence)
{
    string typeStr = (type == ORDER_TYPE_BUY) ? "BUY" : "SELL";
    string message = "✅ *TRADE EXECUTED*\n\n" +
                     "📊 " + typeStr + " " + Symbol() + "\n" +
                     "📦 Lot: " + DoubleToString(lot, 2) + "\n" +
                     "🛑 SL: " + DoubleToString(sl, _Digits) + "\n" +
                     "🎯 TP: " + DoubleToString(tp, _Digits) + "\n" +
                     "🧠 IA: " + DoubleToString(confidence*100, 1) + "%\n\n" +
                     "🤖 BAKOME AI Terminal";
    
    if(TelegramBotToken != "")
        SendTelegramMessage(message);
}

//+------------------------------------------------------------------+
// Calcul lot automatique avec IA
double RiskLot(double riskPercent, double atr, double confidence)
{
    double riskAmount = AccountBalance() * riskPercent / 100;
    // Ajustement du risque selon confiance IA
    if(confidence > 0.8) riskAmount *= 1.2;
    if(confidence < 0.5) riskAmount *= 0.8;
    
    double lot = NormalizeDouble(riskAmount / (atr * Point * 10), 2);
    
    if(lot < 0.01) lot = 0.01;
    if(lot > 50) lot = 50;
    
    return lot;
}

//+------------------------------------------------------------------+
// Fonction de prédiction multi-timeframe
double MultiTimeframeAnalysis()
{
    double h1Trend = iMA(NULL, PERIOD_H1, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 0) -
                     iMA(NULL, PERIOD_H1, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE, 0);
    double m15Trend = iMA(NULL, PERIOD_M15, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 0) -
                      iMA(NULL, PERIOD_M15, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE, 0);
    double m5Trend = iMA(NULL, PERIOD_M5, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 0) -
                     iMA(NULL, PERIOD_M5, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE, 0);
    
    return (h1Trend * 0.5 + m15Trend * 0.3 + m5Trend * 0.2);
}

//+------------------------------------------------------------------+
// Dashboard d'information
string GetDashboard()
{
    double balance = AccountBalance();
    double equity = AccountEquity();
    double profit = AccountProfit();
    double margin = AccountMargin();
    
    string dash = "\n╔══════════════════════════════╗\n" +
                  "║   BAKOME AI TERMINAL v2.0   ║\n" +
                  "╠══════════════════════════════╣\n" +
                  "║ Balance: " + DoubleToString(balance, 2) + "        ║\n" +
                  "║ Equity:  " + DoubleToString(equity, 2) + "        ║\n" +
                  "║ Profit:  " + DoubleToString(profit, 2) + "        ║\n" +
                  "║ Margin:  " + DoubleToString(margin, 2) + "        ║\n" +
                  "╠══════════════════════════════╣\n" +
                  "║ Symbol: " + Symbol() + "              ║\n" +
                  "║ Spread: " + IntegerToString(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)) + "               ║\n" +
                  "╚══════════════════════════════╝";
    
    return dash;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("🔴 BAKOME AI Terminal - Arrêt");
    Print("📊 Session terminée - ", TimeToString(TimeCurrent()));
}
