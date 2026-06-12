#include <Trade\trade.mqh>
      CTrade            Trade;
      CPositionInfo     posInfo;
      COrderInfo        ordInfo;

          enum LotSizingEnum   {
               LowRiskPreset = 5,                   //low risk set 20% annual (0.25% load)
               MidRiskPreset = 4,                   // mid risk set 20% annual
               HighRiskPreset = 3,
               ExtremeRiskPreset = 7,
               LotsEquity = 2,
               LotsBalance = 1,
               FixedLots = 0,
  };

    enum AllowBuySellEnum {
               AllowSell2 = 2,
               AllowBuy1 = 1,
               AllowBuySell = 0,

  };

    enum eMaxDrawdownAction {
               IgnorNewUntilReset = 3,
               IgnorNewSignals = 2,
               CloseStopTradingUnitRestart = 3,
               CloseStopTradingFor24h = 0,

  };

  enum eDrawdownCalculation {
               ThisStrategy = 1,
               TheAccount = 0,
  };



  struct SymbolInformation {

             string      SymbolName;
             datetime    LastMainTFUpdate;
             datetime    LastOPOTFUpdate;
             int         UpdateCounter;
             bool        CanBuy;
             bool        CanSell;
             datetime    CurrentBarTime;
             datetime    PreviousBarTime;
             double      ClosePrice;
             bool        GridOpened;
             bool        OPOTriggered;
             double      SmartDistanceMultiplier;
             double      BBWidth;
             int         LastBarIndex;
             int         CurrentBarIndex;
             long        PatternValue;
             double      PatternPrice;
             bool        PatternSearchActive;
             bool        TradingAllowedToday;
             bool        PreviousDayTradingAllowed;
             int         LastDayOfWeek;
             double      MaxGridLotMultiplier;
             double      LastBuyAvgPrice;
             double      LastSellAvgPrice;
             double      LastBuyTP;
             double      LastSellTP;
             datetime    LastBuyGridTime;
             datetime    LastSellGridTime;
  }

  

  input group "<<<<======== Select the risk settings ========>>>>"

      input    bool                  AllowOpeningNewGrid                = true ;     
      input    LotSizingEnum         LotSizingMethod                    = 5 ;
      input    double                LotSizingValueFixed                = 0.01 ;
      input    double                LotSizingValueDynamic              = 10000 ;
      input    double                LotSizingValueDepositLoadPercent   = 0.25 ;
      input    bool                  FixedInitialDeposit                = false ;
      input    double                MaximunLot                         = 100 ;
      input    bool                  AutoSplit                          = false ;
      input    double                MaximunSpread                      = 10 ;
      input    int                   MaximunSlippage                    = 10 ;
      input    int                   MaximunSymbols                     = 2 ;
      input    bool                  AllowHedging                       = true ;
      input    bool                  AllTredingOnHolidays               = false ;
      input    AllowBuySellEnum      AllowToBuySell                     = 0 ;
      input    double                MinimumFreeMargin                  = 0 ;
      input    double                MaximumDrawdown                    = 100 ;
      input    double                MaximumDrawdownMoney               = 0 ;
      input    eMaxDrawdownAction    MaximumDrawdownAction              = 0 ;
      input    eDrawdownCalculation  DrawdownCalculation                = 1 ;
      
  input group "<<<==== Select the Strategy setting and symbols used ====>>>"

      input    string                Symbols                            = "AUDNZD,AUDCAD,NZDCAD" ;
      input    int                   HourToStartTrading                 = 0 ;
      input    int                   HourToStopTrading                  = 23 ;
      input    int                   BollingerBandsPeriod               = 35 ;
      input    int                   RSI_Period                         = 20 ;
      input    int                   RSI_Value                          = 15 ;

      
  input group "<<<===== Select TP settings =====>>>"

      input    double                InitialTP                          = 10 ;
      input    bool                  WeightedTP                         = true ;
      input    double                GridTP                             = 0 ;
      input    int                   BreakEvenAfterThisLevel            = 0 ;
      input    bool                  HideTP                             = false ;
      input    bool                  Use_OPO_Method                     = false ;
      input    ENUM_TIMEFRAMES       OPO_TimeFrame                      = 15 ;
      input    bool                  SmartTP                            = false ;
      input    bool                  DoNotAdjustTPUnlessNewGrid         = false ;
      

   input group "<<<===== Select SL setings =====>>>"

      input    double                GridSL                             = 0 ;
      input    double                HideSL                             = false ;
      

   input group "<<<===== Adjust the grid distance and multipliers =====>>>"

      input    int                   TradeDistance                      = 35 ;
      input    bool                  SmartDistance                      = true ;
      input    double                TradeMultiplier_2nd                = 1 ;
      input    double                TradeMultiplier_3rd                = 2 ;
      input    double                TradeMultiplier_6th                = 1.5 ;
      input    int                   MaximumTrades                      = 9 ;
      input    int                   GridLevelToStart                   = 1 ;
      input    bool                  KeepOriginalProfitLotSize          = false ;

      
   input group "<<<=== Change the comment and UID if needed ===>>>"

      input    string                TradeComment                       = "Waka" ;
      input    int                   UID                                = 0 ; 
      input    bool                  ShowPanel                          = true ;

      

      // Global Variables

      int                   TickCounter                  = 0 ;
      ENUM_TIMEFRAMES       MainTimeFrame                = PERIOD_M15;
      SymbolInformation     SymbolArray[];
      int                   MagicNumberBase              = 8888 ;
      double                Epsilon                      = 0.0000001 ;
      int                   LastUpdateMinute             = -1 ;
      long                  LastTimerCheck               = 0 ;
      int                   CurrentHour                  = 0 ;
      bool                  DrawdownTriggred             = false ;
      int                   DrawdownCooldownHours        = 0 ;
      bool                  StopTradingUntilRestart      = false ;
      int                   LastProcessedHour            = -1 ;
      bool                  SymbolsListError             = false ;
      double                InitialBalance               = 0.0 ;
      bool                  Initialized                  = true ;

      
     int handle_MA[];
     int handle_Std[];
     int handle_RSI[];
     int handle_ATR96[];
     int handle_ATR672[];

     

     

      

int OnInit(){

 

    Print(TradeComment + " -> Initializing...");

    ChartSetInteger(0, CHART_SHOW_GRID, true);

    TesterHideIndicators(true);

    Comment("wakka demo");

    DrawdownCooldownHours = 0;
    StopTradingUntilRestart = false;
    DrawdownTriggred = false;

   

    if(!MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_OPTIMIZATION))

        EventSetTimer(5);

        LastTimerCheck = TimeCurrent();

    if(!ParseAndInitializeSymbols()) {
      Print(TradeComment + "Error: Failed to initialise symbol");
      return INIT_FAILED
    ;}

    ArrayResize(handle_MA,       ArraySize(SymbolArray));
    ArrayResize(handle_Std,      ArraySize(SymbolArray));
    ArrayResize(handle_RSI,      ArraySize(SymbolArray));
    ArrayResize(handle_ATR96,    ArraySize(SymbolArray));
    ArrayResize(handle_ATR672,   ArraySize(SymbolArray));
    
    for(int i = 0; i < ArraySize(SymbolArray); i++) {
        handle_MA[i]     = iMA(SymbolArray[i].SymbolName, MainTimeFrame, BollingerBandsPeriod+1, 0, MODE_SMA, PRICE_CLOSE);
        handle_Std[i]    = iStdDev(SymbolArray[i].SymbolName, MainTimeFrame, BollingerBandsPeriod+1, 0, MODE_SMA, PRICE_CLOSE);
        handle_RSI[i]    = iRSI(SymbolArray[i].SymbolName, MainTimeFrame, RSI_Period, PRICE_CLOSE);
        handle_ATR96[i]  = iATR(SymbolArray[i].SymbolName, MainTimeFrame, 96);
        handle_ATR672[i] = iATR(SymbolArray[i].SymbolName, MainTimeFrame, 672);
        
        if(handle_MA[i]     == INVALID_HANDLE || handle_Std[i]   == INVALID_HANDLE ||
           handle_RSI[i]    == INVALID_HANDLE || handle_ATR96[i] == INVALID_HANDLE ||
           handle_ATR672[i] == INVALID_HANDLE) {
              Print(TradeComment + ": Failed to create indicator handles for ", SymbolArray[i].SymbolName);
              return INIT_FAILED;
           }
    }

        

        

   return(INIT_SUCCEEDED);

  

  }

//+------------------------------------------------------------------+

//| Expert deinitialization function                                 |

//+------------------------------------------------------------------+

void OnDeinit(const int reason)

  {

//---

   

  }

//+------------------------------------------------------------------+

//| Expert tick function                                             |

//+------------------------------------------------------------------+

void OnTick()

  {

//---

   

  }
  
  
  // 