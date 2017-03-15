//+-------------------------------------------------------------------------------------------------+
//|                                                                                 PowerTool 4.mq4 |
//|                                                                        Copyright 2017, AMT Corp |
//|                                                                                 www.AMTCorp.com |
//+-------------------------------------------------------------------------------------------------+
#property copyright "Copyright 2016, AMT Corp"
#property link      "www.AMTCorp.com"
#property version   "1.00"
#property strict
#property description "PowerTool 4 - Triple Timeframes"

/* 
    * The core code is based on [MVTS_4_HFLF_Model_A.mq4] 
    
    * PowerTool 4 attempts to trade "Leg of The Year" trend, i.e., 
      weekly drift that makes the maximum range of the year.

    * Thence, one application of robot is on one trend leg
    
*/

/*
  Find line with tag "TODO" for pending work
*/

//+-------------------------------------------------------------------------------------------------+
//| INSERT GENERIC REUSABLE FUNCTIONS                                                               |
//+-------------------------------------------------------------------------------------------------+

#include <PowerToolIncludes.mqh>



//+-------------------------------------------------------------------------------------------------+
//| DEFINITIONS                                                                                     |
//+-------------------------------------------------------------------------------------------------+

#define   _DAYSECONDS_ 86400  // 1day = 24hr * 60min * 60sec = 86400sec


/*
sat19feb17
Rooting out the code to bare skeleton. Remove all non-core elements.
Use [MVTS_4_HFLF_Model_A.mq4] as master ; I can copy back everything into this code.

          ******** Non-core elements should go to PowerToolIncludes.mqh ********

*/






//+-------------------------------------------------------------------------------------------------+
//| SYSTEM NAMING AND FILE NAMING                                                                   |
//+-------------------------------------------------------------------------------------------------+
    
string  SystemName      = "Powertool 4 HTF-MTF-LTF on Weekly Trend" ;
string  SystemShortName = "Powertool 4";
string  SystemNameCode  = "PT4";
string  VersionSeries   = "1.00" ;    
string  VersionDate     = "(sun19feb17)" ;



//+-------------------------------------------------------------------------------------------------+
//| ENUMERATION                                                                                     |
//+-------------------------------------------------------------------------------------------------+


enum ENUM_TRADEDIRECTION
  {
    DIR_BUY,
    DIR_SELL
  };


enum ENUM_TRADING_MODE
  {
    TM_LONG    ,
    TM_SHORT   
  };



  
  
  
    //-- Hendy Notes:  
    //-- This is what awesomeness with Powertool 4 application. At one application, you can only 
    //-- long only, or short only application despite HTF direction.
    //-- The Weekly Drift determines the direction of the trade !
    
  
  

//+-------------------------------------------------------------------------------------------------+
//| SYSTEM INTERNAL PARAMETERS                                                                      |
//+-------------------------------------------------------------------------------------------------+

int   PERIOD_TTF = PERIOD_W1 ;
int   PERIOD_HTF = PERIOD_D1 ;
int   PERIOD_MTF = PERIOD_H1 ;
int   PERIOD_LTF = PERIOD_M5 ;


//+-------------------------------------------------------------------------------------------------+
//| EXTERNAL PARAMETERS FOR OPTIMIZATION                                                            |
//+-------------------------------------------------------------------------------------------------+

extern  ENUM_TRADING_MODE   TradeMode                 = TM_LONG  ;
extern  double              RiskPerTrade              = 0.01  ; 
extern  double              NATR                      = 3.5   ;

extern  string              ExclZone_Date             = "2016.06.24";
extern  string              ExclZone_Currency         = "GBP"  ;

extern  bool                BreakEvenStop_Apply       = true  ;

extern  bool                ProfitLock250pips_Apply   = true ; 

        int                 TakeProfit                = 2000  ;       //-- in pips




//+-------------------------------------------------------------------------------------------------+
//| EXCLUSION_IN_ADVANCE ZONE                                                                       |
//+-------------------------------------------------------------------------------------------------+

int     ExclZone_DayBefore  = 1     ;
int     ExclZone_DayAfter   = 1     ;
bool    ExclZone_In         = false ;


//+-------------------------------------------------------------------------------------------------+
//| EXCLUSION LATE SIGNAL IN A TREND                                                                |
//+-------------------------------------------------------------------------------------------------+

int     EntrySignalCountBuy = 0   ;
int     EntrySignalCountSell = 0  ;

int     EntrySignalCountThreshold = 250 ;

//      New trend happens on new analysis of weekly trend in attempt to trade leg of the year
//      Signal is counted over the course of the trend



//+-------------------------------------------------------------------------------------------------+
//| DAILY LOSS LIMIT NUMBER                                                                         |
//+-------------------------------------------------------------------------------------------------+

int     DailyCountEntry  = 0 ;      //-- maximum entry times are 2 per day 



//+-------------------------------------------------------------------------------------------------+
//| INTERNAL VALUE SET                                                                              |
//+-------------------------------------------------------------------------------------------------+


int     MagicNumber_P1            = 68710101  ;
int     MagicNumber_P2            = 68710102  ;
int     MagicNumber_P3            = 68710103  ;



//+-------------------------------------------------------------------------------------------------+
//| LOT SIZING VALUES                                                                               |
//+-------------------------------------------------------------------------------------------------+

double  Lots_p1     ;
double  Lots_p2     ;
double  Lots_p3     ;

//+-------------------------------------------------------------------------------------------------+
//| TARGET PRICE ALL POSITION                                                                       |
//+-------------------------------------------------------------------------------------------------+

double   TargetPriceCommon ;

/*
IMPORTANT:
1. Run the EA on LTF or lower timeframe
2. Magic number is to pick up order if closed
3. Ask, is the code reusable for the NEXT SPRINT ?
*/


//+-------------------------------------------------------------------------------------------------+
//| Point to Price Factor                                                                           |
//+-------------------------------------------------------------------------------------------------+

int     PointToPrice  = 1 ;


//+-------------------------------------------------------------------------------------------------+
//| TRADE FLAGS                                                                                     |
//+-------------------------------------------------------------------------------------------------+

bool    TradeFlag_ProfitThresholdPassed ;
bool    TradeFlag_ClosedOnBigProfit ;




//+-------------------------------------------------------------------------------------------------+
//| BREAKEVEN MANAGEMENT                                                                            |
//+-------------------------------------------------------------------------------------------------+

//-- OnInit initiates the variables

bool    Breakeven_P1_Applied    ;
bool    Breakeven_P2_Applied    ;
bool    Breakeven_P3_Applied    ;


//+-------------------------------------------------------------------------------------------------+
//| PROFIT LOCKING MANAGEMENT                                                                            |
//+-------------------------------------------------------------------------------------------------+

//-- OnInit initiates the variables

bool    ProfitLock250pips_P1_Applied    ;
bool    ProfitLock250pips_P2_Applied    ;
bool    ProfitLock250pips_P3_Applied    ;

double  ProfitLock250pips_NewStopPrice  ;







/***************************************************************************************************/
/***   BEGINNING PROGRAM4   ***/
/***************************************************************************************************/



//+-------------------------------------------------------------------------------------------------+
//| Expert initialization function                                                                  |
//+-------------------------------------------------------------------------------------------------+
int OnInit()
  {   

  //-- To account for 5 digit brokers
  if(Digits == 5 || Digits == 3 || Digits == 1) PointToPrice = 10 ; else PointToPrice = 1; 
  
  
  //-- Reference: [MVTS_4_HFLF_Model_A.mq4] for reporting files
  
  
  //-- Initialize TradeFlag_ClosedOnBigProfit
  TradeFlag_ClosedOnBigProfit = false ;

  
  //-- Initialize Breakeven variables
  Breakeven_P1_Applied  = false   ;
  Breakeven_P2_Applied  = false   ;
  Breakeven_P3_Applied  = false   ;
  
  //-- Take Profit
  TakeProfit = SymbolBasedTargetPrice75Pct( Symbol() ) 
              * 1.0 ;
    
  
  Print("") ;
  Print("") ;
  Print(  "[OnInit]:" ,
          " TakeProfit: ", IntegerToString( TakeProfit )
      );
  Print("") ;
  Print("") ;
  
  
  
  //--- Initialize the generator of random numbers 
  MathSrand(GetTickCount()); 

  
  Alert("Expert Adviser ", SystemName ," ",VersionSeries ," ", VersionDate ," has been launched");



  //-- Marks the end of Initialization    
  Print("OnInit INITIALIZATION is SUCCESSFUL");    

 
  return(INIT_SUCCEEDED);
  }



//+-------------------------------------------------------------------------------------------------+
//| Expert deinitialization function                                                                |
//+-------------------------------------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
    
  
  }









/***************************************************************************************************/
/***   REPORTING FUNCTION   ***/
/***************************************************************************************************/

//-- Use [MVTS_4_HFLF_Model_A.mq4] as master file





/***************************************************************************************************/
/***   EXIT BLOCK   ***/
/***************************************************************************************************/




/*-------------------------------------------------------------------------------------------------*/
/****** EXIT BY EXCLUSION PERIOD RULE ******/
/*-------------------------------------------------------------------------------------------------*/

//-- Exclusion Period Rule is to exit **MARKET** due to extra ordinary event, such as BREXIT


void EXIT_EXCLZONE(
        bool    &closedByTechnicalAnalysis ,
        // double  &RInitPips ,        
        // double  &RMult_Final ,
        string  &comment_exit
        )

// All parameters are borrowed from EXIT_LONG
        
{

    if( ExclZone_In  )
    {

          // --------------------------------------------------------------
          // Exit from *ALL* open position ; BUYING or SELLING 
          // --------------------------------------------------------------
                  
          int   TotalOrders = OrdersTotal();        
          
          for (int i=TotalOrders-1 ; i>=0 ; i--)
          
          //-- "Back loop" because after order close,
          //--  this closed order removed from list of opened orders.
          //-- https://www.mql5.com/en/forum/44043
          
          {
            //-- Select the order
            closedByTechnicalAnalysis = OrderSelect( i , SELECT_BY_POS , MODE_TRADES );
            
            if (!closedByTechnicalAnalysis)
              {
                string _errMsg ;
                  _errMsg = "Failed to select order to close. Error: " + GetLastError() ;
                Print( _errMsg );
                Alert( _errMsg );
                Sleep(3000);
              }                
            
              int type   = OrderType();

              bool result = false;
              
              switch(type)
              {
                //Close opened long positions
                case OP_BUY       : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, Red );
                                    break;
                
                //Close opened short positions
                case OP_SELL      : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, Red );
                                    break;

                //Close pending orders
                case OP_BUYLIMIT  :
                case OP_BUYSTOP   :
                case OP_SELLLIMIT :
                case OP_SELLSTOP  : result = OrderDelete( OrderTicket() );
              }
              
              if(result == false)
              {
                Alert("Order " , OrderTicket() , " failed to close. Error:" , GetLastError() );
                Sleep(3000);
              }            
          }

      
    }

}       // End of void EXIT_EXCLZONE()






/*-------------------------------------------------------------------------------------------------*/
/****** EXIT BUY BY TECHNICAL RULE ******/
/*-------------------------------------------------------------------------------------------------*/

void  EXIT_ALL_POSITIONS(
        bool    &closedByTechnicalAnalysis , 
        // double  &RInitPips ,  
        // double  &RMult_Max ,                
        // double  &RMult_Final ,
        string  &comment_exit
                        )
{
  
          // --------------------------------------------------------------
          // Exit from *ALL* open trade position ; BUYING or SELLING 
          // --------------------------------------------------------------
                  
          int   TotalOrders = OrdersTotal();        
          int   TotalOrdersClosed = 0;
          
          for (int i=TotalOrders-1 ; i>=0 ; i--)
          
          //-- "Back loop" because after order close,
          //--  this closed order removed from list of opened orders.
          //-- https://www.mql5.com/en/forum/44043
          
          {
            //-- Select the order
            closedByTechnicalAnalysis = OrderSelect( i , SELECT_BY_POS , MODE_TRADES );
            
            if (!closedByTechnicalAnalysis)
              {
                string _errMsg ;
                  _errMsg = "Failed to select order to close. Error: " + GetLastError() ;
                Print( _errMsg );
                Alert( _errMsg );
                Sleep(3000);
              }                
            
              int type   = OrderType();

              bool result = false;
              
              switch(type)
              {
                //Close opened long positions
                case OP_BUY       : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, Red );
                                    TotalOrdersClosed++ ;
                                    Print("[EXIT_ALL_POSITIONS]: ",
                                          "Ticket: #" , IntegerToString(OrderTicket()) , " is closed." ,
                                          " OpenPrice(): " ,      DoubleToString( OrderOpenPrice() ,2 )   ,
                                          " ClosedPrice(): " ,    DoubleToString( OrderClosePrice() ,2 )  ,
                                          " OrderCloseTime():",   OrderCloseTime() ,
                                          " OrderProfit(): " ,    DoubleToString(OrderProfit() , 2)  ,
                                          " Total Position closed: " , IntegerToString(TotalOrdersClosed) );
                                    break;
                
                //Close opened short positions
                case OP_SELL      : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, Red );
                                    TotalOrdersClosed++ ;
                                    Print("[EXIT_ALL_POSITIONS]: ",
                                          "Ticket: #" , IntegerToString(OrderTicket()) , " is closed." ,
                                          " OpenPrice(): " ,      DoubleToString( OrderOpenPrice() ,2 )   ,
                                          " ClosedPrice(): " ,    DoubleToString( OrderClosePrice() ,2 )  ,
                                          " OrderCloseTime():",   OrderCloseTime() ,
                                          " OrderProfit(): " ,    DoubleToString(OrderProfit() , 2)  ,
                                          " Total Position closed: " , IntegerToString(TotalOrdersClosed) );
                                    break;

                //Close pending orders
                case OP_BUYLIMIT  :
                case OP_BUYSTOP   :
                case OP_SELLLIMIT :
                case OP_SELLSTOP  : result = OrderDelete( OrderTicket() );
              }
              
              if(result == false)
              {
                Alert("Order " , OrderTicket() , " failed to close. Error:" , GetLastError() );
                Sleep(3000);
              }            
          }
          
          comment_exit = 
              "[EXIT_ALL_POSITIONS]: " + 
              "All " + IntegerToString(TotalOrdersClosed) + " are exited.";
              
          Print( comment_exit );
          
} // End of void EXIT_ALL_POSITIONS




// void EXIT_LONG(

        // bool    &closedByTechnicalAnalysis ,
        // bool    &flag_P1_OrderOpen ,
        // int     &ticket_P1 ,
        // int     &ticket_P1_lastclosed ,     
        // // double  &RInitPips ,  
        // // double  &RMult_Max ,                
        // // double  &RMult_Final ,
        // string  &comment_exit
        // )
// {


        // //-- Google
        // //-- how to close all open positions MT4
        
        
        // closedByTechnicalAnalysis = OrderClose( ticket_P1 , Lots , OrderClosePrice() , 10 , clrYellow );
        
        // if(closedByTechnicalAnalysis == false)
          // {
            // Alert("Error closing order #" , ticket_P1) ;
          // }
          
        // //-- CHECK CLOSING ORDER IN THE LOG USING MODE_HISTORY
        // if( closedByTechnicalAnalysis == true )
          // {
            
            // flag_P1_OrderOpen = false ;
            
            // ticket_P1_lastclosed = ticket_P1 ;
            
            // if( OrderSelect( ticket_P1 , SELECT_BY_TICKET , MODE_HISTORY ) )
              // {
                // Print(              "EXIT MANAGEMENT EXIT FROM BUYING: ",
                                    // "Ticket#/OrderCloseTime()/OrderClosePrice()/Cause of Close: "
                        // ,"#",       OrderTicket() , " vs " , ticket_P1
                        // ," / ",     OrderCloseTime()
                        // ," / ",     OrderClosePrice()                                    
                        // ," / ",     "MACDH Exit HTF downtick"
                    // );                           
                    
                    // comment_exit = "MACDH Exit HTF downtick" ;
                    
              // }                                                  
              // // RMult_Final = ( OrderClosePrice() - OrderOpenPrice() ) / ( RInitPips * Point ) ; 
          // }   // endof if( closedByTechnicalAnalysis == true )                      
       // // end of if( OrderCloseTime() == 0 )                  

// }       // End of void EXIT_LONG()





/*-------------------------------------------------------------------------------------------------*/
/****** EXIT SHORT BY TECHNICAL RULE ******/
/*-------------------------------------------------------------------------------------------------*/


// void EXIT_SHORT(

        // bool    &closedByTechnicalAnalysis ,
        // bool    &flag_P1_OrderOpen ,
        // int     &ticket_P1 ,
        // int     &ticket_P1_lastclosed ,     
        // //double  &RInitPips ,        
        // //double  &RMult_Max ,
        // //double  &RMult_Final ,
        // string  &comment_exit
// )
// {
 
    // //-- Google
    // //-- how to close all open positions MT4
 
    // closedByTechnicalAnalysis = OrderClose( ticket_P1 , Lots , OrderClosePrice() , 10 , clrYellow );

    // if(closedByTechnicalAnalysis == false)
      // {
        // Alert("Error closing order #" , ticket_P1) ;
      // }
      
    // //-- CHECK CLOSING ORDER IN THE LOG USING MODE_HISTORY
    // if( closedByTechnicalAnalysis == true )
      // {
      
        // flag_P1_OrderOpen = false ;
        
        // ticket_P1_lastclosed = ticket_P1 ;
      
        // if( OrderSelect( ticket_P1 , SELECT_BY_TICKET , MODE_HISTORY ) )
          // {
            // Print(              "EXIT MANAGEMENT EXIT FROM SELLING: Ticket#/OrderCloseTime()/OrderClosePrice()/Cause of Close: "
                    // ,"#",       OrderTicket(), " vs " , ticket_P1
                    // ," / ",     OrderCloseTime()
                    // ," / ",     OrderClosePrice()                                    
                    // ," / ",     "MACDH Exit HTF uptick"
                // );
            
            // comment_exit = "MACDH Exit HTF uptick" ;
            
          // }
        // // RMult_Final = ( OrderOpenPrice() - OrderClosePrice() ) / ( RInitPips * Point ) ;
      // } // end of if( closedByTechnicalAnalysis == true )                  

// }       // End of void EXIT_SHORT()





/*-------------------------------------------------------------------------------------------------*/
/****** EXIT JOURNALING - BY TECHNICAL RULE ******/
/*-------------------------------------------------------------------------------------------------*/


/*-------------------------------------------------------------------------------------------------*/
/****** EXIT JOURNALING - BY STOP / TARGET ******/
/*-------------------------------------------------------------------------------------------------*/










/***************************************************************************************************/
/***   ENTRY BLOCK   ***/
/***************************************************************************************************/




void EXECUTE_ENTRY_BUY_P1(
        double  &atr_1 ,    
        bool    &closedByTechnicalAnalysis ,    
        bool    &flag_P1_OrderOpen ,            
        int     &ticket_P1 
        // double  &MAEPips ,
        // double  &MFEPips ,
        // double  &RMult_Max ,
        // double  &RMult_Final         
            )      
  {

  
    // TradeFlag_ClosedOnBigProfit must be FALSE to continue
    if( TradeFlag_ClosedOnBigProfit == true )
    {
      Print("[EXECUTE_ENTRY_BUY_P1]:" ,
        " TradeFlag_ClosedOnBigProfit is TRUE.", 
        " No New Trade entered." ,
        " EXECUTE_ENTRY_BUY_P1() is cancelled"
        );
      return;
    }
    
  
  
    // P1 MUST NOT EXISTS
          ticket_P1 = FindTicket( MagicNumber_P1 );        
    bool  res       = OrderSelect( ticket_P1 , SELECT_BY_TICKET );                           
    if( res == true && OrderType()==OP_BUY &&  OrderCloseTime() == 0 ) 
    {
      Print(  "[EXECUTE_ENTRY_BUY_P1]:" ,
        " Position P1 exists.", 
        " Ticket #" , IntegerToString(ticket_P1) ,
        " EXECUTE_ENTRY_BUY_P1() is cancelled");
      // Position exists, not closed, exit procedure
      return;
    } 
    
    // DailyCountEntry MUST be < 2
    if ( DailyCountEntry >=  2) 
    {
      Print("[EXECUTE_ENTRY_BUY_P1]: " ,
            "DailyCountEntry is " , IntegerToString(DailyCountEntry) );
      return;
    }
  
  
    // BUY P1


    double  plannedStop     = Bid - NATR * atr_1 ;
    
    if( (NATR * atr_1) > 15 * Point * PointToPrice )    // Cap stop distance to 15 pips
      {
        plannedStop = Bid - 15 * Point * PointToPrice ;
        Print("[EXECUTE_ENTRY_BUY_P1]: " ,
              "----> CAP Distance 15 pips is reached" , 
              " planned stop = " , DoubleToString(plannedStop , 4) 
             );
      }
      
    double  priceAsk        = Ask;
    double  plannedTarget   = Bid + TakeProfit * Point * PointToPrice  ;    
    
    //-- Feed for plannedTarget of P2 and P3
    TargetPriceCommon = plannedTarget ;
    
    ENUM_TRADEDIRECTION     direction = DIR_BUY ;
    
    Lots_p1 = LotSize( priceAsk , plannedStop , direction );        
    
    ticket_P1 = OrderSend(      
                    Symbol()
                ,   OP_BUY 
                ,   Lots_p1
                ,   priceAsk 
                ,   3
                ,   plannedStop
                ,   plannedTarget
                ,   "Entry Buy Signal #: " + IntegerToString( EntrySignalCountBuy )
                ,   MagicNumber_P1 
                ,   0
                ,   clrGreen
                );


      //*****************//
      //*** DEBUGGING ***//
      //*****************//
      Print(
              "[EXECUTE_ENTRY_BUY_P1]:"
            , " Ticket P1#: "     , IntegerToString(ticket_P1)
            , " Bid: "            , DoubleToString(Bid ,2)
            , " NATR: "           , DoubleToString(NATR ,1)
            , " atr_1: "          , DoubleToString(atr_1 ,5)
            , " atr_1 pips: "     , DoubleToString((atr_1 / (Point * PointToPrice) ) ,1) 
            , " Distance: "       , DoubleToString( NATR * atr_1 , 5)
            , " Distance pips: "  , DoubleToString( (NATR * atr_1)/(Point * PointToPrice) ,2)
            , " Plan Tgt Price: " , DoubleToString( plannedTarget , 2 )
            , " Plan Target Pips: ",  DoubleToString( (plannedTarget - priceAsk)/(Point * PointToPrice) , 0)
            , " Lot: "            , DoubleToString( Lots_p1 , 2)
          );

          
    if(ticket_P1 < 0)
      {
        int _errNumber = GetLastError();
        Alert("[EXECUTE_ENTRY_BUY_P1]: " ,
              " Error Sending Order BUY!" ,
              " Error Number: "      , IntegerToString( _errNumber ) ,
              " Error Description: " , GetErrorDescription( _errNumber )
              );
      }
    else
      {
        
        // increase daily count entry after entry
        DailyCountEntry++ ;
        
            //-- DEBUGGING
            if( DailyCountEntry >= 2 )
            {
              Print("[EXECUTE_ENTRY_BUY_P1]: " ,
                    "DailyCountEntry: " , IntegerToString(DailyCountEntry) );
            }
        
        // mark the order is opened 
        flag_P1_OrderOpen = true ;
        
        // mark closed by technical analysis is false
        closedByTechnicalAnalysis = false ;
        
        // RESET Trade profit threshold flag 
        TradeFlag_ProfitThresholdPassed = false ; 
        
        // RESET Breakeven_P1_Applied
        Breakeven_P1_Applied = false ;
        
        // RESET ProfitLock250pips_P1_Applied
        ProfitLock250pips_P1_Applied = false  ;

  
      //*****************//
      //*** DEBUGGING ***//
      //*****************//
        
        //-- Add text under arrow
        string  entryDetails1 ;
        string  entryDetails2 ;
        string  entryDetails3 ;
        entryDetails1 = 
                          "P1 Ticket #" + IntegerToString(ticket_P1)
              + "/ \n" +  "Time: "      + TimeToStr(Time[0] , TIME_MINUTES )
              + "/ \n" +  "Ask: "       + DoubleToString(priceAsk , 2)
              + "/ \n" +  "NATR: "      + DoubleToString(NATR , 1)
              ;
        entryDetails2 = 
                          "ATR: "       + DoubleToString(atr_1 , 4)
              + "/ \n" +  "Stop: "      + DoubleToString(plannedStop , 2)
              + "/ \n" +  "Dist Pips: " + DoubleToString((NATR * atr_1)/(Point * PointToPrice) , 2)
              + "/ \n" +  "LotSize: "   + DoubleToString(Lots_p1 , 4)
              ;
        entryDetails3 =
                          "Target: "    + DoubleToString(plannedTarget , 2)
                    ;
        string  txtName = "entdtl1 " + TimeToStr(Time[0] , TIME_DATE|TIME_MINUTES ) ;
        ObjectCreate( txtName , OBJ_TEXT , 0 , Time[0] , Low[1] - 12.0 * Point );
        ObjectSetText( txtName , entryDetails1 ,9 , "Arial" , clrGreen );
        
                txtName = "entdtl2 " + TimeToStr(Time[0] , TIME_DATE|TIME_MINUTES ) ;
        ObjectCreate( txtName , OBJ_TEXT , 0 , Time[0] , Low[1] - 14.0 * Point );
        ObjectSetText( txtName , entryDetails2 ,9 , "Arial" , clrGreen );
        
                txtName = "entdtl3 " + TimeToStr(Time[0] , TIME_DATE|TIME_MINUTES ) ;
        ObjectCreate( txtName , OBJ_TEXT , 0 , Time[0] , Low[1] - 16.0 * Point );
        ObjectSetText( txtName , entryDetails3 ,9 , "Arial" , clrGreen );

        // Initialize trading journal
        // MAEPips     = 0.0 ;
        // MFEPips     = 0.0 ;
        // RMult_Max   = 0.0 ;
        // RMult_Final = 0.0 ;
        
        // #TRICKY FOUND
        // RInitPips   = (OrderOpenPrice() - OrderStopLoss()) / Point() ;
        // OrderOpenPrice() / OrderStopLoss() : 0.0 / 0.0 
        // OrderOpenPrice() and OrderStopLoss() ARE AVAILABLE IN THE NEXT TICK !!!
        
        
        
        // Validate how much the slippage
        //if( OrderSelect(ticket_P1 , SELECT_BY_TICKET , MODE_TRADES ) == true )
        //  {
        //    double actualOpenPrice = OrderOpenPrice();
        //    Print( "SLIPPAGE TEST: Price Ask vs ActualEntry Price and difference: " 
        //            , priceAsk , " / " , actualOpenPrice , " / " , (actualOpenPrice - priceAsk) );
        //  }
        

      }



  } // End of EXECUTE_ENTRY_BUY_P1()
  

  


void EXECUTE_ENTRY_BUY_P2(
        double  &atr_1 ,    
        bool    &closedByTechnicalAnalysis ,    
        bool    &flag_P2_OrderOpen ,            
        int     &ticket_P2  
        // double  &MAEPips ,
        // double  &MFEPips ,
        // double  &RMult_Max ,
        // double  &RMult_Final         
            )      
  {


    //-- P1 must Exists
    //-- P1 must be profitable
    //-- if both criteria above not met, exit the procedure
    int   ticket_P1 = FindTicket( MagicNumber_P1 );        
    bool  res = OrderSelect( ticket_P1 , SELECT_BY_TICKET );                           
    if( res == true && OrderType()==OP_BUY &&  OrderCloseTime() == 0 ) 
    {      
      // P1 exists
      if (OrderProfit() <= 0.0) 
      {
        Print("[EXECUTE_ENTRY_BUY_P2]:" ,
              " P1 is not profitable,", 
              " P1 Ticket #" , IntegerToString(ticket_P1) ,
              " so that, EXECUTE_ENTRY_BUY_P2 is cancelled.") ;
        // P1 MUST be profitable, otherwise exit procedure
        return;
      }
      
      // P1 exists and profitable
      Print("[EXECUTE_ENTRY_BUY_P2]:" ,
            " P1 exists ", 
            " Ticket #" , IntegerToString(ticket_P1) ,
            " and is profitable. EXECUTE_ENTRY_BUY_P2 may be proceeded.") ;
     
    }     
    else
    {
      // P1 not exists
      Print("[EXECUTE_ENTRY_BUY_P2]:" ,
            "P1 NOT EXISTS") ;
      return  ;
    }
    
  
    //-- P2 must NOT exist
    //-- if P2 exists, exit the procedure
    ticket_P2 = FindTicket( MagicNumber_P2 ) ;
    res = OrderSelect( ticket_P2 , SELECT_BY_TICKET ) ;
    if( res==true && OrderType()==OP_BUY && OrderCloseTime() == 0 )
    {
      Print("[EXECUTE_ENTRY_BUY_P2]:" ,
            " Position P2 exists ticket #" , IntegerToString(ticket_P2) , ". EXECUTE_ENTRY_BUY_P2() is cancelled");
      // Position exists, not closed, exit procedure
      return;      
    }

    // DailyCountEntry MUST be < 2
    if ( DailyCountEntry >=  2) 
    {
      Print("[EXECUTE_ENTRY_BUY_P2]:" ,
            " DailyCountEntry is " , IntegerToString(DailyCountEntry) );
      return;
    }    
    
  
    // BUY P2

    double  plannedStop     = Bid - NATR * atr_1 ;
    
    if( (NATR * atr_1) > 15 * Point * PointToPrice )    // Cap stop distance to 15 pips
      {
        plannedStop = Bid - 15 * Point * PointToPrice ;
        Print("[EXECUTE_ENTRY_BUY_P2]:" ,
              " ----> CAP Distance 15 pips is reached" , 
              " planned stop = " , DoubleToString(plannedStop , 4) 
             );
      }
      
  
    

    double  priceAsk        = Ask;
            //plannedTarget   = Bid + TakeProfit * Point * PointToPrice  ;
            //-- plannedTarget uses plannedTarget of P1
    double  plannedTarget = TargetPriceCommon ;
  
    ENUM_TRADEDIRECTION     direction = DIR_BUY ;
    
    Lots_p2   = LotSize( priceAsk , plannedStop , direction );        
    
    ticket_P2 = OrderSend(      
                    Symbol()
                ,   OP_BUY 
                ,   Lots_p2
                ,   priceAsk 
                ,   3
                ,   plannedStop
                ,   plannedTarget
                ,   "Entry Buy Signal #: " + IntegerToString( EntrySignalCountBuy )
                ,   MagicNumber_P2 
                ,   0
                ,   clrGreen
                );
  
  
      //*****************//
      //*** DEBUGGING ***//
      //*****************//
      Print(
              "[EXECUTE_ENTRY_BUY_P2]: "
            , " Ticket P2#: "     , IntegerToString(ticket_P2)
            , " Bid: "            , DoubleToString(Bid ,4)
            , " NATR: "           , DoubleToString(NATR ,2)
            , " atr_1: "          , DoubleToString(atr_1 ,5)
            , " atr_1 pips: "     , DoubleToString((atr_1 / (Point * PointToPrice) ) ,1) 
            , " Distance: "       , DoubleToString( NATR * atr_1 , 5)
            , " Distance pips: "  , DoubleToString( (NATR * atr_1)/(Point * PointToPrice) ,2)
            , " Plan Tgt Price: " , DoubleToString( plannedTarget , 2 )
            , " Plan Target Pips: ",  DoubleToString( (plannedTarget - priceAsk)/(Point * PointToPrice) , 0)
            , " Lot: "            , DoubleToString( Lots_p2 , 2)
          );
    
  
    if(ticket_P2 < 0)
      {
        int _errNumber = GetLastError();
        Alert("[EXECUTE_ENTRY_BUY_P2]: " ,
              " Error Sending Order BUY!" ,
              " Error Number: "      , IntegerToString( _errNumber ) ,
              " Error Description: " , GetErrorDescription( _errNumber )
              );
      }
    else
      {
        
        // increase daily count entry after entry
        DailyCountEntry++ ;
        
            //-- DEBUGGING
            if( DailyCountEntry >= 2 )
            {
              Print("[EXECUTE_ENTRY_BUY_P2]: " ,
                    "DailyCountEntry: " , IntegerToString(DailyCountEntry) );
            }
                
        // mark the order is opened 
        flag_P2_OrderOpen = true ;
        
        // mark closed by technical analysis is false
        closedByTechnicalAnalysis = false ;

        // RESET Breakeven_P2_Applied
        Breakeven_P2_Applied = false ;
        
        // RESET ProfitLock250pips_P2_Applied
        ProfitLock250pips_P2_Applied = false  ;        
        
      //*****************//
      //*** DEBUGGING ***//
      //*****************//
        
        //-- Add text under arrow
        string  entryDetails1 ;
        string  entryDetails2 ;
        string  entryDetails3 ;
        entryDetails1 = 
                          "P2 Ticket #" + IntegerToString(ticket_P2)
              + "/ \n" +  "Time: "      + TimeToStr(Time[0] , TIME_MINUTES )
              + "/ \n" +  "Ask: "       + DoubleToString(priceAsk , 2)
              + "/ \n" +  "NATR: "      + DoubleToString(NATR , 1)
              ;
        entryDetails2 = 
                          "ATR: "       + DoubleToString(atr_1 , 4)
              + "/ \n" +  "Stop: "      + DoubleToString(plannedStop , 2)
              + "/ \n" +  "Dist Pips: " + DoubleToString((NATR * atr_1)/(Point * PointToPrice) , 2)
              + "/ \n" +  "LotSize: "   + DoubleToString(Lots_p2 , 4)
              ;
        entryDetails3 = 
                          "Target: "    + DoubleToString( plannedTarget, 2)
                    ;
        string  txtName = "entdtl1 " + TimeToStr(Time[0] , TIME_DATE|TIME_MINUTES ) ;
        ObjectCreate( txtName , OBJ_TEXT , 0 , Time[0] , Low[1] - 12.0 * Point );
        ObjectSetText( txtName , entryDetails1 ,9 , "Arial" , clrRed );
        
                txtName = "entdtl2 " + TimeToStr(Time[0] , TIME_DATE|TIME_MINUTES ) ;
        ObjectCreate( txtName , OBJ_TEXT , 0 , Time[0] , Low[1] - 14.0 * Point );
        ObjectSetText( txtName , entryDetails2 ,9 , "Arial" , clrRed );

                txtName = "entdtl3 " + TimeToStr(Time[0] , TIME_DATE|TIME_MINUTES ) ;
        ObjectCreate( txtName , OBJ_TEXT , 0 , Time[0] , Low[1] - 16.0 * Point );
        ObjectSetText( txtName , entryDetails3 ,9 , "Arial" , clrRed );        
      }

  } // End of EXECUTE_ENTRY_BUY_P2()  





void EXECUTE_ENTRY_BUY_P3(
        double  &atr_1 ,
        bool    &closedByTechnicalAnalysis ,
        bool    &flag_P3_OrderOpen ,
        int     &ticket_P3 
        // double  &MAEPips ,
        // double  &MFEPips ,
        // double  &RMult_Max ,
        // double  &RMult_Final         
            )      
  {


    //-- P1 must Exists
    //-- P1 must be profitable
    //-- if both criteria above not met, exit the procedure
    int   ticket_P1 = FindTicket( MagicNumber_P1 );        
    bool  res = OrderSelect( ticket_P1 , SELECT_BY_TICKET );                           
    if( res == true && OrderType()==OP_BUY &&  OrderCloseTime() == 0 ) 
    {      
      // P1 exists
      if (OrderProfit() <= 0.0) 
      {
        Print("[EXECUTE_ENTRY_BUY_P3]:" ,
              " P1 is not profitable,", 
              " P1 Ticket #" , IntegerToString(ticket_P1) ,
              " so that, EXECUTE_ENTRY_BUY_P2 is cancelled.") ;
        // P1 MUST be profitable, otherwise exit procedure
        return;
      }
      
      // P1 exists and profitable
      Print("[EXECUTE_ENTRY_BUY_P3]:" ,
            " P1 exists ", 
            " Ticket #" , IntegerToString(ticket_P1) ,
            " and is profitable. EXECUTE_ENTRY_BUY_P3 may be proceeded given P2 profitable.") ;
     
    }     
    else
    {
      // P1 not exists
      Print("[EXECUTE_ENTRY_BUY_P3]:" ,
            " P1 NOT EXISTS") ;
      return  ;
    }

    
    //-- P2 must exist
    //-- P2 must be profitable
    //-- if both criteria above is not met, exit the procedure
    int   ticket_P2 = FindTicket( MagicNumber_P2 );
          res = OrderSelect( ticket_P2 , SELECT_BY_TICKET );                           
    if( res == true && OrderType()==OP_BUY &&  OrderCloseTime() == 0 ) 
    {      
      // P2 exists
      if (OrderProfit() <= 0.0) 
      {
        Print("[EXECUTE_ENTRY_BUY_P3]:" ,
              " P2 is not profitable,", 
              " P2 Ticket #" , IntegerToString(ticket_P2) ,
              " so that, EXECUTE_ENTRY_BUY_P3 is cancelled.") ;
        // P2 MUST be profitable, otherwise exit procedure
        return;
      }
      
      // P2 exists and profitable
      Print("[EXECUTE_ENTRY_BUY_P3]:" ,
            " P2 exists ",
            " Ticket #", IntegerToString( ticket_P2 ) ,
            " and is profitable. EXECUTE_ENTRY_BUY_P3 may be proceeded.") ;
     
    }     
    else
    {
      // P2 not exists
      Print("[EXECUTE_ENTRY_BUY_P3]:" ,
            " P2 NOT EXISTS") ;
      return  ;
    }
  
  
    //-- P3 must NOT exist
    //-- if P3 exists, exit the procedure
    ticket_P3 = FindTicket( MagicNumber_P3 ) ;
    res = OrderSelect( ticket_P3 , SELECT_BY_TICKET ) ;
    if( res==true && OrderType()==OP_BUY && OrderCloseTime() == 0 )
    {
      Print("[EXECUTE_ENTRY_BUY_P3]: " ,
            "Position P3 exists ticket #", IntegerToString(ticket_P3),". EXECUTE_ENTRY_BUY_P3() is cancelled");
      // Position exists, not closed, exit procedure
      return;      
    }

    // DailyCountEntry MUST be < 2
    if ( DailyCountEntry >=  2) 
    {
      Print("[EXECUTE_ENTRY_BUY_P3]: " ,
            "DailyCountEntry is " , IntegerToString(DailyCountEntry) );
      return;
    }    
    
  
    // BUY P3

    double  plannedStop     = Bid - NATR * atr_1 ;
    
    if( (NATR * atr_1) > 15 * Point * PointToPrice )    // Cap stop distance to 15 pips
      {
        plannedStop = Bid - 15 * Point * PointToPrice ;
        Print("[EXECUTE_ENTRY_BUY_P3]: " ,
              "----> CAP Distance 15 pips is reached" , 
              " planned stop = " , DoubleToString(plannedStop , 4) 
             );
      }

      
      
      
    double  priceAsk        = Ask;
            // double  plannedTarget   = Bid + TakeProfit * Point * PointToPrice  ;
    
    double  plannedTarget = TargetPriceCommon ;        
    
    ENUM_TRADEDIRECTION     direction = DIR_BUY ;
    
    Lots_p3   = LotSize( priceAsk , plannedStop , direction );        
    
    ticket_P3 = OrderSend(      
                    Symbol()
                ,   OP_BUY 
                ,   Lots_p3
                ,   priceAsk 
                ,   3
                ,   plannedStop
                ,   plannedTarget
                ,   "Entry Buy Signal #: " + IntegerToString( EntrySignalCountBuy )
                ,   MagicNumber_P3 
                ,   0
                ,   clrGreen
                );
  
  
      //*****************//
      //*** DEBUGGING ***//
      //*****************//
      Print(
              "[EXECUTE_ENTRY_BUY_P3]: "
            , " Ticket P3#: "     , IntegerToString(ticket_P3)
            , " Bid: "            , DoubleToString(Bid ,4)
            , " NATR: "           , DoubleToString(NATR ,2)
            , " atr_1: "          , DoubleToString(atr_1 ,5)
            , " atr_1 pips: "     , DoubleToString((atr_1 / (Point * PointToPrice) ) ,1) 
            , " Distance: "       , DoubleToString( NATR * atr_1 , 5)
            , " Distance pips: "  , DoubleToString( (NATR * atr_1)/(Point * PointToPrice) ,2)
            , " Plan Tgt Price: " , DoubleToString( plannedTarget , 2 )
            , " Plan Target Pips: ",  DoubleToString( (plannedTarget - priceAsk)/(Point * PointToPrice) , 0)
            , " Lot: "            , DoubleToString( Lots_p2 , 2)
          );
    
                  
    if(ticket_P3 < 0)
      {
        int _errNumber = GetLastError();
        Alert("[EXECUTE_ENTRY_BUY_P3]: " ,
              " Error Sending Order BUY!" ,
              " Error Number: "      , IntegerToString( _errNumber ) ,
              " Error Description: " , GetErrorDescription( _errNumber )
              );
      }
    else
      {
        
        // increase daily count entry after entry
        DailyCountEntry++ ;
        
            //-- DEBUGGING
            if( DailyCountEntry >= 2 )
            {
              Print("[EXECUTE_ENTRY_BUY_P3]: " ,
                    "DailyCountEntry: " , IntegerToString(DailyCountEntry) );
            }
                
        // mark the order is opened 
        flag_P3_OrderOpen = true ;
        
        // mark closed by technical analysis is false
        closedByTechnicalAnalysis = false ;

        // RESET Breakeven_P3_Applied
        Breakeven_P3_Applied = false ;
        
        
        // RESET ProfitLock250pips_P3_Applied
        ProfitLock250pips_P3_Applied = false  ;
        
        
      //*****************//
      //*** DEBUGGING ***//
      //*****************//
        
        //-- Add text under arrow
        string  entryDetails1 ;
        string  entryDetails2 ;
        string  entryDetails3 ;
        entryDetails1 = 
                          "P3 Ticket #" + IntegerToString(ticket_P3)
              + "/ \n" +  "Time: "      + TimeToStr(Time[0] , TIME_MINUTES )
              + "/ \n" +  "Ask: "       + DoubleToString(priceAsk , 2)
              + "/ \n" +  "NATR: "      + DoubleToString(NATR , 1)
              ;
        entryDetails2 = 
                          "ATR: "       + DoubleToString(atr_1 , 4)
              + "/ \n" +  "Stop: "      + DoubleToString(plannedStop , 2)
              + "/ \n" +  "Dist Pips: " + DoubleToString((NATR * atr_1)/(Point * PointToPrice) , 2)
              + "/ \n" +  "LotSize: "   + DoubleToString(Lots_p2 , 4)
              ;
        entryDetails3 = 
                          "Target: "    + DoubleToString( plannedTarget, 2)
                    ;
        string  txtName = "entdtl1 " + TimeToStr(Time[0] , TIME_DATE|TIME_MINUTES ) ;
        ObjectCreate( txtName , OBJ_TEXT , 0 , Time[0] , Low[1] - 12.0 * Point );
        ObjectSetText( txtName , entryDetails1 ,9 , "Arial" , clrYellow );
        
                txtName = "entdtl2 " + TimeToStr(Time[0] , TIME_DATE|TIME_MINUTES ) ;
        ObjectCreate( txtName , OBJ_TEXT , 0 , Time[0] , Low[1] - 14.0 * Point );
        ObjectSetText( txtName , entryDetails2 ,9 , "Arial" , clrYellow);

                txtName = "entdtl3 " + TimeToStr(Time[0] , TIME_DATE|TIME_MINUTES ) ;
        ObjectCreate( txtName , OBJ_TEXT , 0 , Time[0] , Low[1] - 16.0 * Point );
        ObjectSetText( txtName , entryDetails3 ,9 , "Arial" , clrYellow );                
      }

  } // End of EXECUTE_ENTRY_BUY_P3()  






  
  
  




// void EXECUTE_ENTRY_SELL_P1(          
        // double  &atr_1 ,                      
        // bool    &closedByTechnicalAnalysis ,    
        // bool    &flag_P1_OrderOpen ,            
        // int     &ticket_P1 ,                        
        // double  &MAEPips ,
        // double  &MFEPips ,
        // double  &RMult_Max ,
        // double  &RMult_Final         
            // ) 
// {


      // // SELL      
        

            // double  plannedStop     = Ask + NATR * atr_1 ;
            
            // if( (NATR * atr_1) > 0.0015 )           // Cap the distance 15 pips
              // {
                // plannedStop = Ask + 0.0015 ;
                // Print("----> CAP Distance 15 pips is reached");
              // }
            
            // double  priceBid        = Bid;
            // double  plannedTarget   = Ask - TakeProfit * Point * PointToPrice ;            
            
            // ENUM_TRADEDIRECTION     direction = DIR_SELL ;
            
            // Lots    = LotSize( priceBid , plannedStop , direction );    
        
            // ticket_P1 = OrderSend(      Symbol(), OP_SELL
                        // ,   Lots
                        // ,   priceBid
                        // ,   10
                        // ,   plannedStop
                        // ,   plannedTarget
                        // ,   "Entry Sell Signal #: " + IntegerToString( EntrySignalCountSell )
                        // ,   Magic_P1
                        // ,   0
                        // ,   clrRed 
                        // );
                                
            // if(ticket_P1 < 0)
              // {
                // Alert("Error Sending Order!");
              // }
            // else
              // {

                // // mark the order is opened 
                // flag_P1_OrderOpen = true ;

                // // mark closed by technical analysis is false
                // closedByTechnicalAnalysis = false ;
                
                // // Initialize tracking variables
                // MAEPips     = 0.0 ;
                // MFEPips     = 0.0 ;
                // RMult_Max   = 0.0 ;
                // RMult_Final = 0.0 ;
               
                // // #TRICKY FOUND
                // // RInitPips   = (OrderOpenPrice() - OrderStopLoss()) / Point() ;
                // // OrderOpenPrice() / OrderStopLoss() : 0.0 / 0.0 
                // // OrderOpenPrice() and OrderStopLoss() ARE AVAILABLE IN THE NEXT TICK !!!
                               
                                
                // /*
                // // Validate how much the slippage
                // if( OrderSelect(ticket_P1 , SELECT_BY_TICKET , MODE_TRADES ) == true )
                  // {
                    // double actualOpenPrice = OrderOpenPrice();
                    // Print( "SLIPPAGE TEST: Price Bid vs ActualEntry Price and difference: " 
                            // , priceBid , " / " , actualOpenPrice  , " / " , (priceBid - actualOpenPrice) );
                  // }                
                // */


              // }
              
        
  // }     // End of EXECUTE_ENTRY_SELL()





//+-------------------------------------------------------------------------------------------------+
//| Lot Sizing                                                                                      |
//+-------------------------------------------------------------------------------------------------+

double LotSize(
    double              &priceEntry ,
    double              &plannedStop ,
    ENUM_TRADEDIRECTION &direction
    )
  {
    //double  _lots_ = AccountEquity() / 10000 * LotsPer10K ;    
    //-- OVERRIDE FOR DEBUGGING
    //double _lots_ = LotsFix ;
    
    double  distance ;    
    double  lotsize ;
    double  riskdollar ;    
    
    riskdollar = AccountEquity() * RiskPerTrade ;
    
    if( direction == DIR_BUY )
      {
        distance    = priceEntry - plannedStop ;
      }
    else if(direction == DIR_SELL)
      {
        distance    = plannedStop - priceEntry ;
      }
      
    Print(    "[LotSize]:"
            , " Distance: "         ,   DoubleToStr( distance   , 4)
            , " priceEntry: "       ,   priceEntry 
            , " plannedStop: "      ,   DoubleToString( plannedStop , 4)
            , " AccountEquity: "    ,   DoubleToStr(AccountEquity() , 2 )
            , " RiskDollar: "       ,   DoubleToStr(riskdollar , 2 )
            , " RiskPerTrade: "     ,   RiskPerTrade
            
         );
    
    // Failsafe to prevent distance
    if(distance < 1 * Point * PointToPrice ) // if distance less than 1 pip, no trade!
      {
        lotsize = 1 ;
        Print("[LotSize]:"
            , " *** ERROR: Stoploss Distance to is ZERO ***" );
      }
    else
      {
        double riskdoloverdist ;
        
        riskdoloverdist = riskdollar / distance ;
        lotsize = riskdoloverdist * (10/10000.0) ;    // 100 is leverage level
        
        Print("[LotSize]:" ,
              
              " Distance pips: "        , DoubleToStr( (distance / (Point * PointToPrice))  , 0)  ,
              " RiskDollar: "           , DoubleToString(riskdollar , 2) ,
              " Distance: "             , DoubleToStr( distance   , 4)  ,
              " RiskdollarOverDist: "   , DoubleToStr( riskdoloverdist   , 4)  ,
              " LotSize: "              , DoubleToStr( lotsize  , 2)
              );
        
        // IMPORTANT: division on double variable MUST USE double value
        // Example:
        // WONT WORK: (1/100000)
        // WILL WORK: (1.0 / 100000)
        
        //Print(      "INNER IF lotsize: ", lotsize 
        //        ,   " RiskDollar over Distance: " , DoubleToStr( riskdoloverdist , 2 )
        //    );
      }
      
    //Print( "OUTER IF lotsize: ", lotsize );
    return lotsize  ;    
  }







/*/////////////////////////////////////////////////////////////////////////////////////////////////*/
/*///////////////////////////////      EXPERT OnTick FUNCTION    //////////////////////////////////*/
/*/////////////////////////////////////////////////////////////////////////////////////////////////*/



void OnTick()
  {
    
    
    
    /***********************************************************************************************/
    /***   STARTING BLOCK   ***/
    /***********************************************************************************************/

    
    
    //-- Timeframe controller 
    static bool     IsFirstTick_TTF = false ;
    static int      TTF_Barname_Curr ;
    static int      TTF_Barname_Prev ;
    
    
    static bool     IsFirstTick_HTF = false;
    static int      HTF_Barname_Curr ;
    static int      HTF_Barname_Prev ;
    
    
    static bool     IsFirstTick_MTF = false;
    static int      MTF_Barname_Curr ;
    static int      MTF_Barname_Prev ;   
    

    static bool     IsFirstTick_LTF = false;
    static int      LTF_Barname_Curr ;
    static int      LTF_Barname_Prev ;   
    
    //-- Ticket controller
    static int      ticket_P1 = 0;
    static int      ticket_P1_lastclosed = 0;
    
    static int      ticket_P2 = 0;
    static int      ticket_P2_lastclosed = 0;

    static int      ticket_P3 = 0;
    static int      ticket_P3_lastclosed = 0;    
    
    //-- Closed order controller between CLOSED BY TECHINCAL ANALYSIS VS CLOSED BY STOPLOSS/TARGETPROFIT
    static bool     flag_P1_OrderOpen = false; 
    static bool     flag_P2_OrderOpen = false; 
    static bool     flag_P3_OrderOpen = false;     
    
    
    //-- Reporting controller to prevent double reporting after closed order by technical analysis
    //-- not to be reported again in the next tick after getting history pool selectorder
    static bool     closedByTechnicalAnalysis = false;
    
    
    //-- Trading Journal variables
    //-- Refer to [MVTS_4_HFLF_Model_A.mq4] for Trading Journal Variables
        
        /*---------------------------------------------------------------------------------*\
        | *)    "In fact, another definition of expectancy is the average R-value of the 
        |       system." Van Tharp [2008], p.19, "Definitive Guide to Position Sizing"
        \*---------------------------------------------------------------------------------*/
        
        
    
    //-- Equity Drawdown Variables
    //-- Refer to [MVTS_4_HFLF_Model_A.mq4] for Equity Drawdown variables

    
        //-- ICAGR / ACAGR / MAR / PDD / FREQUENCY
            // ICAGR is for annual return. Here it is replaced with 
            // quarterly timeframe, hence ICQGR
            // Instantaneously Compounded Quarterly Growth Rate
       
        
        
        
    // Counter for tick per hour
    static int      TickCountPerHour = 0 ;        

    
    
    //-- Warning Controller 
    
    // Preventing printing equity level more than once
    static bool      InvalidEquityLevel = false ;


    //--- Comment for exit
    string comment_exit ;

    
    /***********************************************************************************************/
    /***   BLOCK TO PREVENT NON-VALID LOGIC   ***/
    /***********************************************************************************************/

    
    // if( MA_Fast >= MA_Slow )
    // {
    // return;
    // }
     
     
   //-- Invalid Equity Level
   
   if( AccountEquity() < 100 && InvalidEquityLevel == false )
     {
        // Preventing printing equity level more than once
        InvalidEquityLevel = true; 
        
        Print(
            "WARNING: AccountEquity() < 100. Account Equity is $" , DoubleToStr( AccountEquity() , 2 )
            );
        
        return;
     }
   
   
   
   
    /***********************************************************************************************/
    /***   BLOCK TO OPERATE ON FIRST TICK OF EACH TIME FRAME   ***/
    /***********************************************************************************************/   

    /*   
    Fundamental code for multiple timeframe
    */

    /*
    Pick the higher timeframe
    */


    
    
   
    //+---------------------------------------------------------------------------------------------+
    //| TICK BY TICK MONITORING                                                                     |
    //+---------------------------------------------------------------------------------------------+   

    
    // Track_TradingJournal_Vars(ticket_P1 , MAEPips , MFEPips , RInitPips , RMult_Max , RMult_Final );

    // Track_EquityDrawdown_Vars(ticket_P1 , InitialEquity  , PeakEquity , DrawdownEquity , 
    //                    DrawdownPercent , DrawdownMaxEquity , DrawdownMaxPercent , 
    //                    RecoveryRatio );


    // Increase tick count per HOUR (MTF)
    TickCountPerHour++ ;

    
    
    

    //+---------------------------------------------------------------------------------------------+
    //| MARK EXCLUSION IN ADVANCE ZONE                                                              |
    //+---------------------------------------------------------------------------------------------+   

    // Avoid events:
    //  1. CHF unpegging
    //  2. BREXIT

    // 
    // ExclZone_DayBefore ExclZone_DayAfter

    ExclZone_In = 
      ( 
      ( StringToTime(ExclZone_Date) - ExclZone_DayBefore * _DAYSECONDS_ )  <= TimeCurrent() 
      &&
      TimeCurrent() <= (StringToTime(ExclZone_Date) + ExclZone_DayAfter * _DAYSECONDS_ ) )
      
      &&
      (
          // Exclude for the intended currency
          StringFind( Symbol() , ExclZone_Currency , 0 ) >= 0     // IMPORTANT: ">= 0"
      )         
      ;

    if( ExclZone_In )
    {
      // Close all open position
      // Print(ExclZone_Currency +  " location: " + StringFind( Symbol() , ExclZone_Currency , 0 ) );
      Print( "[OnTick]: " , 
          "THIS IS EXCLUSION ZONE. ALL OPEN POSITIONS MUST BE CLOSED. " + 
          "NO NEW POSITION TO ENTER for " + ExclZone_Currency 
          );
    }

    //-- Print up Hello World from MQH
    if( IsFirstTick_TTF ) 
          mqhHelloWorld(); //-- Call the MQH Top Time Frame


    //+---------------------------------------------------------------------------------------------+
    //| SELECT THE FIRST TICK OF TTF (Top Time Frame)                                               |
    //+---------------------------------------------------------------------------------------------+   
    datetime  ThisTime = TimeCurrent();
    int iDay  = ( TimeDayOfWeek(ThisTime) ) % 7 + 1;              // convert day to standard index (1=Mon,...,7=Sun)
    int iWeek = ( TimeDayOfYear(ThisTime) - iDay + 10 ) / 7;      // calculate standard week number
    //-- https://www.mql5.com/en/forum/129771/page2
    
    TTF_Barname_Curr = iWeek ;
    if( TTF_Barname_Curr != TTF_Barname_Prev )
    {
      IsFirstTick_TTF = true ;            
    }
    else
    {
      IsFirstTick_TTF = false ;
    }
    
    

    
    //+---------------------------------------------------------------------------------------------+
    //| SELECT THE FIRST TICK OF HTF                                                                |
    //+---------------------------------------------------------------------------------------------+   
    

    HTF_Barname_Curr = Day();
    if(HTF_Barname_Curr != HTF_Barname_Prev )
     {
        IsFirstTick_HTF = true ;
     }
    else
     {
        IsFirstTick_HTF = false ;
     }

    /*
    When HTF_Barname_Curr = HTF_Barname_Prev, IsFirstTick_HTF = FALSE !!
    */
   
   
   
   

    //+---------------------------------------------------------------------------------------------+
    //| SELECT THE FIRST TICK OF DAILY BAR AND PROCEED THE FLOW AT FIRST (OPENING BAR) TICK ONLY    |
    //+---------------------------------------------------------------------------------------------+   

    if( IsFirstTick_HTF )
    {
    
    // Draw vertical line
    // ==========================================

    string theDayTme = TimeToStr( Time[0] , TIME_DATE|TIME_MINUTES ) ;
    string VlineName = "VL" + theDayTme ;

    VLineCreate(0, VlineName , 0 , 0 , clrBlueViolet , STYLE_SOLID , 1 , false, false, true , 0) ;

    // Add description 
    ObjectSetText( VlineName , "Line for: " + theDayTme , 9 , "Arial" , clrBlueViolet );



    // Add text
    // ---------------------------------------------------

    //--- reset the error value 
    ResetLastError(); 

    string txtName = "TXT" + theDayTme ;
    double verticalOffset = Point * 10.0 * 5.0 ;


    //--- create Text object 

    ObjectCreate( txtName , OBJ_TEXT , 0 , Time[0] , Close[1] + verticalOffset );
    ObjectSetText( txtName , DayOfWeekString( DayOfWeek() ) ,9 , "Arial" , clrRed );
    ObjectSet( txtName , OBJPROP_ANGLE , 90.0 );

    
    }
    




    //+---------------------------------------------------------------------------------------------+
    //| SELECT THE FIRST TICK OF MTF                                                                |
    //+---------------------------------------------------------------------------------------------+   
    
    /*
    Control the timing on Hourly bar
    Exit procedure if the current tick is not the FIRST TICK OF LOWEST TIMEFRAME   
    */    
    

    
    MTF_Barname_Curr = Hour() ;
   
    if(MTF_Barname_Curr != MTF_Barname_Prev )
     {
        IsFirstTick_MTF = true ;
     }
    else
     {
        IsFirstTick_MTF = false ;
     }
     
    /*
    When MTF_Barname_Curr = MTF_Barname_Prev , IsFirstTick_MTF  = FALSE !!
    */







    //+---------------------------------------------------------------------------------------------+
    //| SELECT THE FIRST TICK OF LTF AND PROCEED THE FLOW AT FIRST (OPENING BAR) TICK ONLY          |
    //+---------------------------------------------------------------------------------------------+   
    
    /*
    Control the timing on Hourly bar
    Exit procedure if the current tick is not the FIRST TICK OF LOWEST TIMEFRAME   
    */    
    
      
    
    LTF_Barname_Curr = (Minute() / 5) * 5 ;
    // The nature of integer division is like "FLOOR" function 6 / 5 = 1
    // The formula forces the value 0 , 5 , 10 , 15 ... 55
    
   
    if(LTF_Barname_Curr != LTF_Barname_Prev )
     {
        IsFirstTick_LTF = true ;
     }
    else
     {
        IsFirstTick_LTF = false ;
     }
     
    if( !IsFirstTick_LTF )
     {
        
        /*******************************************************************************************/
        /***   ENDING BLOCK OF ONTICK()   ***/
        /*******************************************************************************************/
        
        // This line is to ensure previous bar name carries LTF bar name
        LTF_Barname_Prev = LTF_Barname_Curr ;

        return;

        
     }
     

    
    /***********************************************************************************************/
    /***   FROM THIS POINT FORWARD, ONLY FIRST TICK OF LTF OPERATES   ***/
    /***********************************************************************************************/
    //-- Other ticks in the LTF bar are skipped 

    
    
    

    //+---------------------------------------------------------------------------------------------+
    //| DETERMINE IF BIG PROFIT HAVE EVER BEEN ACHIEVED                                             |
    //+---------------------------------------------------------------------------------------------+   
    //-- PREVENT NEW ENTRY IF BIG PROFIT HAS BEEN ACHIEVED
    //-- BIG PROFIT IS "LEG OF THE YEAR"; YOU WAIT UNTIL NEXT YEAR  
    //-- OR YOU DISCOVER A STRONG WEEKLY "V" or "A" PATTERN OCCURS IN THE SAME YEAR
    
    if( IsFirstTick_HTF )
    {
      Print("[OnTick]: *** TradeFlag_ClosedOnBigProfit: ", BoolToStr(TradeFlag_ClosedOnBigProfit) );
    }


    if( IsFirstTick_HTF && TradeFlag_ClosedOnBigProfit==false )
    {

          Print("[OnTick]:",
              " TradeFlag_ClosedOnBigProfit: " , BoolToStr(TradeFlag_ClosedOnBigProfit) );

          bool    selectedOrder   ;
          int     totalHistoryOrders = OrdersHistoryTotal();
          double  orderProfit       ;
          double  orderProfitPips   ;

          //-------------------------------------------------------
          // NOTE NOTE NOTE
          // Big Profit should be checked against P1 only !!
          // use the magic number for P1
          // if only the magic number works!
          // if not working, then, the system needs checking
          // all historical closed trade
          //-------------------------------------------------------

          for (int i=totalHistoryOrders-1 ; i>=0 ; i--)
          
          //-- "Back loop" because after order close,
          //--  this closed order removed from list of opened orders.
          //-- https://www.mql5.com/en/forum/44043
          
          {
            //-- Select the order
            selectedOrder = OrderSelect( i , SELECT_BY_POS , MODE_HISTORY );
            
            if (!selectedOrder)
              {
                
                string  _errMsg     ;
                int     _lastErrorNum  ; 
                
                  _lastErrorNum = GetLastError() ;
                  _errMsg = 
                        "Failed to select HISTORY order. Error: " + _lastErrorNum  +
                        " Desc: " + GetErrorDescription( _lastErrorNum )
                    ;
                Print( _errMsg );
                Alert( _errMsg );
                Sleep(3000);
              }                
            
              /* Print("[OnTick]>[if(TradeFlag_ClosedOnBigProfit==false)] "
                  " Ticket: #",           IntegerToString( OrderTicket() )        ,
                  " OpenPrice(): " ,      DoubleToString( OrderOpenPrice() ,2 )   ,
                  " ClosedPrice(): " ,    DoubleToString( OrderClosePrice() ,2 )  ,
                  " OrderCloseTime():",   OrderCloseTime()
                  ); */
              
              if( selectedOrder == true 
                  && (OrderType()==OP_BUY  || OrderType()==OP_SELL )
                  && OrderCloseTime() != 0 )
              {
                switch( OrderType() ) 
                {
                  case OP_BUY:
                    //-- TO DO orderProfit
                    orderProfit = OrderClosePrice() - OrderOpenPrice();
                  break;
                  case OP_SELL:
                    //-- TO DO orderProfit
                    orderProfit = OrderOpenPrice() - OrderClosePrice();
                  break;
                }
              }
              
              
              
              orderProfitPips  = orderProfit / ( Point * PointToPrice );
              
              Print("Ticket: #" , OrderTicket() 
                  , " OrderProfitPips: " , DoubleToStr( orderProfitPips ,0)  );
              
              if ( orderProfitPips >= 1500 ) 
              //-- TO DO 
              //-- Need symbol-based function that return high profit for closed trade
              //-- 1500 is approximate for USDJPY. 
              //
              {
                TradeFlag_ClosedOnBigProfit = true ;
                break;
              }
          }      
      
    }
    
    
    
    

    // First tick alert

    if( IsFirstTick_HTF )
      {
        //Alert("First tick >>>> HTF") ;
      }      
    if( IsFirstTick_MTF )
      {
        //Alert("First tick >>>> MTF") ;
      }
    if(IsFirstTick_LTF)
      {
        //Alert("First tick > LTF");
      }
   


    //+---------------------------------------------------------------------------------------------+
    //| TTF INDICATORS                                                                              |
    //+---------------------------------------------------------------------------------------------+

    static double macd_TTF_exit_hist_1  ;
    static double macd_TTF_exit_hist_X  ;
    if( IsFirstTick_TTF )
    {

      macd_TTF_exit_hist_1 = iCustom( NULL , PERIOD_TTF , "MACDH_OnCalc" , 
           18 , 39 , 18 ,
              2 , 1 ) ; 
              // Buffer = 2 / index = 1

      macd_TTF_exit_hist_X = iCustom( NULL , PERIOD_TTF , "MACDH_OnCalc" , 
           18 , 39 , 18 ,
              2 , 2 ) ;         
      // Buffer = 2 / index = 2 
  
  
    
      //*****************//
      //*** DEBUGGING ***//
      //*****************//
      Print(
            "[OnTick]: *** WEEKLY BAR ***"
          + " Date: " + TimeToStr(Time[0] , TIME_DATE|TIME_MINUTES ) 
          + " " + DayOfWeekString( DayOfWeek() )
          + " MACDH WEEKLY [1]: " + DoubleToString( macd_TTF_exit_hist_1 , 4)
          + " MACDH WEEKLY [2]: " + DoubleToString( macd_TTF_exit_hist_X , 4)          
                    );
  
  
    }

   
   
   
   
    //+---------------------------------------------------------------------------------------------+
    //| HTF INDICATORS                                                                              |
    //+---------------------------------------------------------------------------------------------+

    static double sma_HTF_drift_1 ;
    static double sma_HTF_drift_X ;
    
    static double rsi3_HTF_1  ;
    static double rsi3_HTF_2  ;
    
    static bool   rsi3_HTF_cock_UP    ;
    static bool   rsi3_HTF_cock_DOWN  ;

    static double macd_HTF_entry_hist_1 ;
    static double macd_HTF_entry_hist_X ;
    
    static double macd_HTF_exit_hist_1  ;
    static double macd_HTF_exit_hist_X  ;

    // you have to make it static variable to keep 
    // the values between tick call    
    
    if( IsFirstTick_HTF )
    {
    
      // SMA DRIFT
      // ----------------------

      sma_HTF_drift_1 = iMA(NULL , PERIOD_HTF , 5 , 0 , MODE_SMA , PRICE_MEDIAN , 1 );
      sma_HTF_drift_X = iMA(NULL , PERIOD_HTF , 5 , 0 , MODE_SMA , PRICE_MEDIAN , 3 );

      // RSI 3 HTF 
      // ----------------------
      
      rsi3_HTF_1    = iRSI(NULL , PERIOD_HTF , 3 , PRICE_CLOSE , 1) ;
      rsi3_HTF_2    = iRSI(NULL , PERIOD_HTF , 3 , PRICE_CLOSE , 2) ;
      
      
      // RSI 3 HTF - COCKED UP 
      // or COCKED DOWN
      // ----------------------
      
      if( rsi3_HTF_1 > 50.001 && rsi3_HTF_2 <= 50.000 ) 
      {
        rsi3_HTF_cock_UP    = true  ;
        rsi3_HTF_cock_DOWN  = false ;
      }
      
      if( rsi3_HTF_1 < 49.999 && rsi3_HTF_2 >= 50.000 ) 
      {
        rsi3_HTF_cock_UP    = false  ;
        rsi3_HTF_cock_DOWN  = true ;        
      }

      

      // MACD ENTRY
      // ----------------------

      // MACDH uses PRICE_MEDIAN, not PRICE_CLOSE to gauge drift

      macd_HTF_entry_hist_1 = iCustom( NULL , PERIOD_HTF , "MACDH_OnCalc" , 
            12 , 26 , 9 , 
              2 , 1 ) ; 
              // Buffer = 2 / index = 1

      macd_HTF_entry_hist_X = iCustom( NULL , PERIOD_HTF , "MACDH_OnCalc" , 
           12 , 26 , 9 , 
              2 , 2 ) ;         
             // Buffer = 2 / index = 2 


      // MACD EXIT
      // ----------------------

      macd_HTF_exit_hist_1 = iCustom( NULL , PERIOD_HTF , "MACDH_OnCalc" , 
           18 , 39 , 18 ,
              2 , 1 ) ; 
              // Buffer = 2 / index = 1

      macd_HTF_exit_hist_X = iCustom( NULL , PERIOD_HTF , "MACDH_OnCalc" , 
           18 , 39 , 18 ,
              2 , 2 ) ;         
      // Buffer = 2 / index = 2 


    }
    



   
    //+---------------------------------------------------------------------------------------------+
    //| MTF INDICATORS                                                                               |
    //+---------------------------------------------------------------------------------------------+
    
    
    static double rsi_MTF_slow_1 ;
    static double rsi_MTF_slow_X ;
    static double rsi_MTF_fast_1 ;
    static double rsi_MTF_fast_X ;
    
    // you have to make it static variable to keep 
    // the values between tick call
    
    
    if( IsFirstTick_MTF )
    {
    
      rsi_MTF_slow_1 = iRSI(NULL , PERIOD_MTF , 9 , PRICE_CLOSE , 1 );
      rsi_MTF_slow_X = iRSI(NULL , PERIOD_MTF , 9 , PRICE_CLOSE , 2 );        
      
      rsi_MTF_fast_1 = iRSI(NULL , PERIOD_MTF , 6 , PRICE_CLOSE , 1 );
      rsi_MTF_fast_X = iRSI(NULL , PERIOD_MTF , 6 , PRICE_CLOSE , 2 );        

      
      
      // Print the tick count at hour 5 and on the fourth day
      //if( Hour() == 5 && Day() % 4 == 0 )
      //  {                              
      //    Print( "***>> Ticks per hour: ******>> " , TickCountPerHour );
      //  }      
      
      
      TickCountPerHour = 0 ;              
      
    }
    
    
    
    

    //+---------------------------------------------------------------------------------------------+
    //| LTF INDICATORS                                                                              |
    //+---------------------------------------------------------------------------------------------+

    double bb_LTF_channel1_upper_2 ;
    double bb_LTF_channel2_lower_2 ;
    
    double lrco_LTF_1fast_1  ;
    double lrco_LTF_1fast_2  ;
    double lrco_LTF_2slow_1  ;
    double lrco_LTF_2slow_2  ;
   
    static double trailingstop_BUY   = -999.0;
    static double trailingstop_SELL  = 999.0;
   
    double atr_LTF_36bar_1   ;
    
    
    
    
    bb_LTF_channel1_upper_2 = iBands(NULL , PERIOD_M5 , 36 , 1.0 , 0 , PRICE_TYPICAL , MODE_UPPER , 2 ) ;
    bb_LTF_channel2_lower_2 = iBands(NULL , PERIOD_M5 , 36 , 1.0 , 0 , PRICE_TYPICAL , MODE_LOWER , 2 ) ;
    
    
    lrco_LTF_1fast_1 = iCustom( NULL , PERIOD_LTF , "LR_MA_OnCalc" , 
               10 , PRICE_TYPICAL , 0 ,
                  0 , 1 ) ; 
                  // Buffer = 0 / index = 1
    lrco_LTF_1fast_2 = iCustom( NULL , PERIOD_LTF , "LR_MA_OnCalc" , 
               10 , PRICE_TYPICAL , 0 ,
                  0 , 2 ) ; 
                  // Buffer = 0 / index = 2

    lrco_LTF_2slow_1 = iCustom( NULL , PERIOD_LTF , "LR_MA_OnCalc" , 
               30 , PRICE_TYPICAL , 0 ,
                  0 , 1 ) ; 
                  // Buffer = 0 / index = 1

    lrco_LTF_2slow_2 = iCustom( NULL , PERIOD_LTF , "LR_MA_OnCalc" , 
               30 , PRICE_TYPICAL , 0 ,
                  0 , 2 ) ; 
                  // Buffer = 0 / index = 2
                  
    atr_LTF_36bar_1 = iATR( NULL , PERIOD_LTF , 3*12 , 0 ) ;


   
   
   
   
   
   
   
   
   
 
    /*-----------------------------------------------------------------------------------*/
    /****** DEBUGGING SECTION ******/
    /*-----------------------------------------------------------------------------------*/
    //-- Reading indicator values

    if( IsFirstTick_HTF )
      {
      
        // Print(
            // "SMA(5) = "         , DoubleToString( sma_HTF_drift_1 , 4)         , " / " ,
            // "MACDH(12,26,9)[1]: "   , DoubleToString( macd_HTF_entry_hist_1 , 5)  , " / " ,
            // "MACDH(18,36,18)[1]: "  , DoubleToString( macd_HTF_exit_hist_1 , 5)  , " / " ,
            // "MACDH(12,26,9)[2]: "   , DoubleToString( macd_HTF_entry_hist_X , 5)  , " / " ,
            // "MACDH(18,36,18)[2]: "  , DoubleToString( macd_HTF_exit_hist_X , 5)
            // );
          
        
        // VALUES PASSED QA !
        
        /*
    2016.07.01 00:05  EURUSD SMA(5) = 1.1087 / MACDH(12,26,9): -0.00197 / MACDH(18,36,18): -0.00235
    2016.07.04 00:00  EURUSD SMA(5) = 1.1077 / MACDH(12,26,9): -0.00156 / MACDH(18,36,18): -0.00225
    2016.07.05 00:00  EURUSD SMA(5) = 1.1098 / MACDH(12,26,9): -0.00109 / MACDH(18,36,18): -0.00203
    2016.07.06 00:00  EURUSD SMA(5) = 1.1110 / MACDH(12,26,9): -0.00121 / MACDH(18,36,18): -0.00221
    2016.07.07 00:00  EURUSD SMA(5) = 1.1106 / MACDH(12,26,9): -0.00104 / MACDH(18,36,18): -0.00216
        */
        
      }
      
      
    if( IsFirstTick_MTF )
      {
        //Print (
        //     "RSI(6): " , DoubleToStr(rsi_MTF_fast_1 , 4) , " / " ,
        //     "RSI(9): " , DoubleToStr(rsi_MTF_slow_1 , 4)
        //     );
        // MOST VALUES MATCHES WITH THAT OF TERMINAL. FEW VALUES DO NOT MATCH.
        // I STILL PASS IT              
      }     
    
    

    if( IsFirstTick_LTF )
      {
      
        // Print(
          // "BB Upper: "  , DoubleToStr(bb_LTF_channel1_upper_2, 6 ) , " / " ,
          // "BB Lower: "  , DoubleToStr(bb_LTF_channel2_lower_2, 6) , " / " ,
          // "LR(10): "    , DoubleToStr(lrco_LTF_1fast_1 , 6) , " / " ,
          // "LR(30): "    , DoubleToStr(lrco_LTF_2slow_1 , 6) 
        // );
        
        // // VALUES PASSED QA !
      }

   
   
   
    /***********************************************************************************************/
    /***    BREAKEVEN STOP MANAGEMENT - BUYING ONLY  ***/
    /***********************************************************************************************/   
  
    //-- On P1: when P2 is in, P1 is to breakeven
    //-- On P2 and P3: When profit of P2 (and P3) greater than 100 pips, is to break even
    //-- This logic bit operates on LTF (M5)

    if( BreakEvenStop_Apply == true )
    {
      
      bool  resP1       ;
      bool  resP2       ;
      bool  resP3       ;
      bool  resModify   ;
      int   _errNumber  ;
  
  
      //+-------------------------------------------------------------------------------------------+
      //| On P1                                                                                     |
      //+-------------------------------------------------------------------------------------------+         

      
      if( Breakeven_P1_Applied == false )
      {
          ticket_P1 = FindTicket( MagicNumber_P1 );        
          resP1     = OrderSelect( ticket_P1 , SELECT_BY_TICKET );                           
          if( resP1 == true && OrderType()==OP_BUY && OrderCloseTime() == 0 ) 
          {
            //-- P1 Exists. Now check P2 if exists
            //-- This portion is only executed in the next tick after P2 is entered, 
            //-- NOT in the same tick of P2 entering
            
            ticket_P2 = FindTicket( MagicNumber_P2 );
            resP2     = OrderSelect( ticket_P2 , SELECT_BY_TICKET )   ;
            
            if( resP2 == true && OrderType()==OP_BUY &&  OrderCloseTime() == 0 )
            {
              //-- P2 exists. Now P1 must be into breakeven          
              // Select P1 again
              resP1 = OrderSelect( ticket_P1 , SELECT_BY_TICKET ) ;
              if ( resP1 ) 
                  {
                      resModify = OrderModify( 
                                  ticket_P1 , 
                                  OrderOpenPrice() ,  
                                  OrderOpenPrice() ,  //-- This is new stoploss price
                                  OrderTakeProfit() , 
                                  0 ,
                                  clrYellow     //-- mark with yellow arrow
                                  );
                                  
                    if( !resModify )
                    {
                      Print("[OnTick]:" ,
                            " >>> >>> >>> Error Modifying P1 to breakeven!" ,
                            " Error Number: "      , IntegerToString( _errNumber ) ,
                            " Error Description: " , GetErrorDescription( _errNumber )
                            );                  
                    }
                    else
                    {
                      
                      Breakeven_P1_Applied = true ; 
                      
                      Print("");
                      Print("[OnTick]:" ,
                            " *** *** P1 is now at breakeven Stop!" ,
                            " Breakeven_P1_Applied: " , BoolToStr( Breakeven_P1_Applied)
                          );
                      Print("");
                      
                    } // End of if( !resModify )
                  }
                  else
                  {
                    //-- Error - no selection P1
                    _errNumber = GetLastError();
                    Print("[OnTick]:" ,
                          " >>> >>> >>> NO SELECTION Error Modifying P1 to breakeven!" ,
                          " Error Number: "      , IntegerToString( _errNumber ) ,
                          " Error Description: " , GetErrorDescription( _errNumber )
                          );
                  }  //-- End of if( resP1 )
            } //-- End of if( resP2 == true ... )
          }   //-- End of if( resP1 == true ... )
            
      } //-- End of if( Breakeven_P1_Applied == false )


      //+-------------------------------------------------------------------------------------------+
      //| On P2                                                                                     |
      //+-------------------------------------------------------------------------------------------+         

      
      if( Breakeven_P2_Applied == false )
      {
          ticket_P2 = FindTicket( MagicNumber_P2 );
          resP2     = OrderSelect( ticket_P2 , SELECT_BY_TICKET )   ;
          if( resP2 == true && OrderType()==OP_BUY &&  OrderCloseTime() == 0 )
          {
            //-- P2 exists. 
            //-- Check if P2 profit pips > 100 pips
            double  profitP2pips = 
                      ( Close[1] - OrderOpenPrice() )  //-- Close[1] is of M5 
                      /
                      ( Point * PointToPrice ) ;   
            
            if ( profitP2pips > 100.0 ) 
            {
                resModify = OrderModify( 
                            ticket_P2 , 
                            OrderOpenPrice() ,  
                            OrderOpenPrice() ,  //-- This is new stoploss price
                            OrderTakeProfit() , 
                            0 ,
                            clrYellow     //-- mark with yellow arrow
                            );
                            
              if( !resModify )
              {
                Print("[OnTick]: " ,
                      " >>> >>> >>> Error Modifying P2 to breakeven!" ,
                      " Error Number: "      , IntegerToString( _errNumber ) ,
                      " Error Description: " , GetErrorDescription( _errNumber )
                      );                  
              }
              else
              {
                Breakeven_P2_Applied = true; 
                
                Print("") ;
                Print("[OnTick]:" ,
                      " *** *** P2 is now at breakeven Stop!" ,
                      " Breakeven_P2_Applied: " , BoolToStr( Breakeven_P2_Applied ) , 
                      " ProfitPips: " , DoubleToString( profitP2pips , 0 ) , " pips."
                      );
                Print("") ;
                
              }
            } //-- End of if( profitP2pips > 100.0 )
          } //-- End of if( resP2 == true ... )
        
      } //-- End of if( Breakeven_P2_Applied == false )
  


      //+-------------------------------------------------------------------------------------------+
      //| On P3                                                                                     |
      //+-------------------------------------------------------------------------------------------+         

      
      if( Breakeven_P3_Applied == false )
      {
          ticket_P3 = FindTicket( MagicNumber_P3 );
          resP3     = OrderSelect( ticket_P3 , SELECT_BY_TICKET )   ;
          if( resP3 == true && OrderType()==OP_BUY &&  OrderCloseTime() == 0 )
          {
            //-- P3 exists. 
            //-- Check if P3 profit pips > 100 pips
            double  profitP3pips = 
                      ( Close[1] - OrderOpenPrice() )  //-- Close[1] is of M5 
                      /
                      ( Point * PointToPrice ) ;   
            
            if ( profitP3pips > 100.0 ) 
            {
                resModify = OrderModify( 
                            ticket_P3 , 
                            OrderOpenPrice() ,  
                            OrderOpenPrice() ,  //-- This is new stoploss price
                            OrderTakeProfit() , 
                            0 ,
                            clrYellow     //-- mark with yellow arrow
                            );
                            
              if( !resModify )
              {
                Print("[OnTick]: " ,
                      " >>> >>> >>> Error Modifying P3 to breakeven!" ,
                      " Error Number: "      , IntegerToString( _errNumber ) ,
                      " Error Description: " , GetErrorDescription( _errNumber )
                      );                  
              }
              else
              {
                Breakeven_P3_Applied = true; 
                
                Print("") ;
                Print("[OnTick]:" ,
                      " *** *** P3 is now at breakeven Stop!" ,
                      " Breakeven_P3_Applied: " , BoolToStr( Breakeven_P3_Applied ) , 
                      " ProfitPips: " , DoubleToString( profitP3pips , 0 ) , " pips."
                      );
                Print("") ;
                
              }
            }   //-- End of if( profitP3pips > 100.0 )
          } //-- End of if( resP3 == true ... )
        
      } //-- End of if( Breakeven_P3_Applied == false )
  
    } //-- End of [if (BreakEvenStop_Apply == true) ]
    
  
  
  
  
    /***********************************************************************************************/
    /***    PROFIT LOCKING 250 PIPS - BUYING ONLY  ***/
    /***********************************************************************************************/   
    
    //-- On P1: when its profit is 1200 pips (i.e., the lowest 25 percentile on strong FX), 
    //-- we move the stop to 250 pips profit for P1, 
    //-- and IF P2, or P2 and P3 exists, all of the stops are moved to the same price
    //-- This logic operates on LTF (M5)
    
    if( ProfitLock250pips_Apply )
    {
      
      bool  resP1       ;
      bool  resP2       ;
      bool  resP3       ;
      bool  resModify   ;
      int   _errNumber  ;
      
      //+-------------------------------------------------------------------------------------------+
      //| On P1                                                                                     |
      //+-------------------------------------------------------------------------------------------+         

      
      if( ProfitLock250pips_P1_Applied == false )
      {
          ticket_P1 = FindTicket( MagicNumber_P1 );        
          resP1     = OrderSelect( ticket_P1 , SELECT_BY_TICKET );                           
          if( resP1 == true && OrderType()==OP_BUY && OrderCloseTime() == 0 ) 
          {
            double  profitP1pips = 
                      ( Close[1] - OrderOpenPrice() )  //-- Close[1] is of M5 
                      /
                      ( Point * PointToPrice ) ;   
                      
            if ( profitP1pips > 1200.0 ) 
            {
              
                //-- This is new stoploss price
                ProfitLock250pips_NewStopPrice = OrderOpenPrice() + 250.0 * (Point * PointToPrice) ;
              
                resModify = OrderModify( 
                            ticket_P1 , 
                            OrderOpenPrice() ,  
                            ProfitLock250pips_NewStopPrice ,  
                            OrderTakeProfit() , 
                            0 ,
                            clrYellow     //-- mark with yellow arrow
                            );
                            
              if( !resModify )
              {
                Print("[OnTick]: " ,
                      " >>> >>> >>> Error Modifying P1 to lock profit at 250 pips!" ,
                      " Error Number: "      , IntegerToString( _errNumber ) ,
                      " Error Description: " , GetErrorDescription( _errNumber )
                      );                  
              }
              else
              {
                ProfitLock250pips_P1_Applied = true; 
                
                Print("") ;
                Print("**** PROFIT LOCKING ****") ;
                Print("[OnTick]:" ,
                      " *** *** P1 is now at 250 pips profit lock !" ,
                      " ProfitLock250pips_P1_Applied: " , BoolToStr( ProfitLock250pips_P1_Applied ) ,
                      " ProfitPips: " , DoubleToString( profitP1pips , 0 ) , " pips."
                      );
                Print("**** PROFIT LOCKING ****") ;
                Print("") ;                
              }
              
            } //-- End of if ( profitP1pips > 1200.0 ) 
          } //-- End of if( resP1 == true ...
      } //-- End of if( ProfitLock250pips_P1_Applied == false )
      
    
      //+-------------------------------------------------------------------------------------------+
      //| On P2                                                                                     |
      //+-------------------------------------------------------------------------------------------+         
      
      if( ProfitLock250pips_P2_Applied == false && ProfitLock250pips_P1_Applied == true )
      {
          ticket_P2 = FindTicket( MagicNumber_P2 );
          resP2     = OrderSelect( ticket_P2 , SELECT_BY_TICKET )   ;
          if( resP2 == true && OrderType()==OP_BUY &&  OrderCloseTime() == 0 )
          {
            //-- P2 exists. 
            //-- Check if P2 opening price < ProfitLock250pips_NewStopPrice

            double  profitP2pips = 
                      ( Close[1] - OrderOpenPrice() )  //-- Close[1] is of M5 
                      /
                      ( Point * PointToPrice ) ;   
            
            if( OrderOpenPrice() < ProfitLock250pips_NewStopPrice )
            {

                resModify = OrderModify( 
                            ticket_P2 , 
                            OrderOpenPrice() ,  
                            ProfitLock250pips_NewStopPrice ,  
                            OrderTakeProfit() , 
                            0 ,
                            clrYellow     //-- mark with yellow arrow
                            );
                            
              if( !resModify )
              {
                Print("[OnTick]: " ,
                      " >>> >>> >>> Error Modifying P2 to lock profit at the same level of P1!" ,
                      " Error Number: "      , IntegerToString( _errNumber ) ,
                      " Error Description: " , GetErrorDescription( _errNumber )
                      );                  
              }
              else
              {
                ProfitLock250pips_P2_Applied = true; 
                
                Print("") ;
                Print("**** PROFIT LOCKING ****") ;
                Print("[OnTick]:" ,
                      " *** *** P2 is now at P1's 250 pips profit lock !" ,
                      " ProfitLock250pips_P2_Applied: " , BoolToStr( ProfitLock250pips_P2_Applied ) ,
                      " ProfitPips: " , DoubleToString( profitP2pips , 0 ) , " pips."
                      );
                Print("**** PROFIT LOCKING ****") ;
                Print("") ;                
              }
              
            } //-- End of if( OrderOpenPrice() < ProfitLock250pips_NewStopPrice )
            
          } //-- End of if( resP2 == true && OrderType()==OP_BUY ...
        
      } //-- End of if( ProfitLock250pips_P2_Applied == false )
      
      

      //+-------------------------------------------------------------------------------------------+
      //| On P3                                                                                     |
      //+-------------------------------------------------------------------------------------------+         
      
      if( ProfitLock250pips_P3_Applied == false && ProfitLock250pips_P1_Applied == true )
      {
          ticket_P3 = FindTicket( MagicNumber_P3 );
          resP3     = OrderSelect( ticket_P3 , SELECT_BY_TICKET )   ;
          if( resP3 == true && OrderType()==OP_BUY &&  OrderCloseTime() == 0 )
          {
            //-- P3 exists. 
            //-- Check if P3 opening price < ProfitLock250pips_NewStopPrice

            double  profitP3pips = 
                      ( Close[1] - OrderOpenPrice() )  //-- Close[1] is of M5 
                      /
                      ( Point * PointToPrice ) ;   
            
            if( OrderOpenPrice() < ProfitLock250pips_NewStopPrice )
            {

                resModify = OrderModify( 
                            ticket_P3 , 
                            OrderOpenPrice() ,  
                            ProfitLock250pips_NewStopPrice ,  
                            OrderTakeProfit() , 
                            0 ,
                            clrYellow     //-- mark with yellow arrow
                            );
                            
              if( !resModify )
              {
                Print("[OnTick]: " ,
                      " >>> >>> >>> Error Modifying P3 to lock profit at the same level of P1!" ,
                      " Error Number: "      , IntegerToString( _errNumber ) ,
                      " Error Description: " , GetErrorDescription( _errNumber )
                      );                  
              }
              else
              {
                ProfitLock250pips_P3_Applied = true; 
                
                Print("") ;
                Print("**** PROFIT LOCKING ****") ;
                Print("[OnTick]:" ,
                      " *** *** P3 is now at P1's 250 pips profit lock !" ,
                      " ProfitLock250pips_P3_Applied: " , BoolToStr( ProfitLock250pips_P3_Applied ) ,
                      " ProfitPips: " , DoubleToString( profitP3pips , 0 ) , " pips."
                      );
                Print("**** PROFIT LOCKING ****") ;
                Print("") ;                
              }
              
            } //-- End of if( OrderOpenPrice() < ProfitLock250pips_NewStopPrice )
            
          } //-- End of if( resP3 == true && OrderType()==OP_BUY ...        
        
      } //-- End of if( ProfitLock250pips_P3_Applied == false )        


    } //-- End of if( ProfitLock250pips_Apply )
  



    
    
    /***********************************************************************************************/
    /***   EXIT MANAGEMENT   ***/
    /***********************************************************************************************/   
  

   
    //+---------------------------------------------------------------------------------------------+
    //| EXIT BY DELIBERATE EXCLUSION DAY / ZONE                                                     |    
    //+---------------------------------------------------------------------------------------------+
   
   
    if( IsFirstTick_LTF == true )
    {
     
        
        
        // EXIT FROM EXCLUSION ZONE
        
        EXIT_EXCLZONE(  
                   closedByTechnicalAnalysis , 
                   // RInitPips , 
                   // RMult_Final,
                   comment_exit
                   );
        

    }  // end of if( IsFirstTick_LTF == true )





    //+---------------------------------------------------------------------------------------------+
    //| EXIT BUY BY TRADING SYSTEM TECHNICAL RULE                                                   |
    //+---------------------------------------------------------------------------------------------+
    
    
    /*-----------------------------------------------------------------------------------*/
    /****** TECHNICAL DEFINITION EXIT BUY ******/
    /*-----------------------------------------------------------------------------------*/
    
    //-- TODO: Exit buy or exit sell, needs weekly MACDH trend change. In this code, it still 
    //-- uses daily MACDH, instead of weekly MACDH.
    
    
    bool exitBuy = false ;
    
    if( IsFirstTick_TTF )
    {
  
  
      //-- Exit rule that I am comfortable with:
      //-- after 1,750 pips profit on P1
      //-- use macd_TTF_exit_hist downtick as exit rule
      //-- This allows profit to work out to USDJPY 1700 pips more, 
      //-- to allow profit grows, 
      //-- to ignore short-term fluctuation, to ignore noises,
      //-- before letting the trend end itself.

      //-- Calculate Order Profit in Pips
      int   ticket_P1 = FindTicket( MagicNumber_P1 );        
      bool  res       = OrderSelect( ticket_P1 , SELECT_BY_TICKET );                           
      if( res == true && OrderType()==OP_BUY &&  OrderCloseTime() == 0 )         
      {
        double  OrderP1ProfitPrice  = Close[1] - OrderOpenPrice() ;
        double  OrderP1ProfitPips   = OrderP1ProfitPrice / (Point * PointToPrice);
        
        //-- Note, Close[1] is the last close of M5 - the lowest time frame, 
        //-- that also happens as the close of W1, because this tick is happening 
        //-- as the first tick of W1

        // Flag the position at high profit
        if( OrderP1ProfitPips >= SymbolBasedTargetPrice67Pct( Symbol() ) ) 
            TradeFlag_ProfitThresholdPassed = true ;
        //-- The flag is reset on entering a new position
        //-- TO DO 
        //-- Need symbol-based function for this function
        

        
        exitBuy = (
                  (macd_TTF_exit_hist_1 < macd_TTF_exit_hist_X)
              &&  TradeFlag_ProfitThresholdPassed   // For USDJPY
              );
        
        //*****************//
        //*** DEBUGGING ***//
        //*****************//
        Print(
                "[OnTick]: "
              , "*** WEEKLY BAR ***"
              , " Close[1]: "           , DoubleToString(Close[1] , 2)
              , " OrderOpenPrice: "     , DoubleToString(OrderOpenPrice() , 2  )
              , " ticket_P1: "          , IntegerToString(ticket_P1)
              , " OrderP1ProfitPrice: " , DoubleToString(OrderP1ProfitPrice , 4)
              , " OrderP1ProfitPips: "  , DoubleToString(OrderP1ProfitPips , 1)
              , " MACDH W1 [1]: "       , DoubleToString(macd_TTF_exit_hist_1 , 4)
              , " MACDH W1 [2]: "       , DoubleToString(macd_TTF_exit_hist_X , 4)
              , " exitBuy: "            , BoolToStr( exitBuy )
            );
      } 
      
      
      // exitBuy = ( 
                  // macd_TTF_exit_hist_1 < 0 
              // &&  macd_TTF_exit_hist_X >= 0
                  // );    //-- A cross down from positive_sign to negative_sign
                  
      

    }
    
    
    
    if( IsFirstTick_HTF == true )
    {    

        //-- Note in TM_LONG ; long-only trade, the exit buy signal exists
        //-- This section should contain techincal definition on technical exit signal
        //-- without considering any ticket !
        //-- The closing should be "CLOSE ALL OPEN POSITION"
        
        // exitBuy = ( 
                  // macd_HTF_exit_hist_1 < 0 
              // &&  macd_HTF_exit_hist_X >= 0
                  // );    //-- A cross down from positive_sign to negative_sign

    }


    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\
    * Notes:
    * --------------
    * On TRAILING STOP CALCULATION, refer to 
    *   C:\Users\Hendy\AppData\Roaming\MetaQuotes\Terminal\50CA3DFB510CC5A8F28B48D1BF2A5702\..
    *   MQL4\Experts\MVTS_3_ATRTrailStop 1.04.mq4
    *
    * Tips:
    * --------------
    * Trailing stop can be on HTF, MTF, or LTF.
    * use IsFirstTick_HTF / IsFirstTick_MTF / IsFirstTick_LTF and ATR value relevant to its timeframe
    * and Low[1] or High[1] from the respective timeframe.
    * The Low[] or the High[] depends on timeframe of the *current chart*
    * To access Low[] or the High[] from different timeframe use iLow() and iHigh() function
    *
    \~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


    
    
    /*-----------------------------------------------------------------------------------*/
    /****** EXECUTION - EXIT BUY ******/
    /*-----------------------------------------------------------------------------------*/     

    if( IsFirstTick_TTF && exitBuy && TradeMode == TM_LONG )
     {
      
        //*****************//
        //*** DEBUGGING ***//
        //*****************//          
          Print( 
          
            "[OnTick] ======== EXIT BUY WEEKLY CALL ===== " , 
             "MACDH TTF(18,36,18)[1]: "  , DoubleToString( macd_TTF_exit_hist_1 , 5) , " / " ,
             "MACDH TTF(18,36,18)[2]: "  , DoubleToString( macd_TTF_exit_hist_X , 5)
            );      
        
      
        //-- The closing should be "CLOSE ALL OPEN POSITION" 
        //-- The logic below is still from older logic that close first position only
        //-- I want simpler logic to close **all open position** 
        
        EXIT_ALL_POSITIONS(
            closedByTechnicalAnalysis   ,
            comment_exit
            );
            
        if( closedByTechnicalAnalysis==true ) 
        {
          
          TradeFlag_ClosedOnBigProfit = true;
          //-- Set flag for Closed on big profit = true
          //-- No more entries after this.
          
          Print( "" );
          Print( "[OnTick]: ****** ALL POSITIONS HAVE BEEN CLOSED IN HIGH PROFIT ***" );
          Print( "[OnTick]: ****** NO MORE TRADE ENTRY AFTER THIS ***" );
          Print( "" );
        }
        
      }    


      

     
    //+---------------------------------------------------------------------------------------------+
    //| EXIT SELL BY TRADING SYSTEM TECHNICAL RULE                                                  |
    //+---------------------------------------------------------------------------------------------+

    
    /*-----------------------------------------------------------------------------------*/
    /****** TECHNICAL DEFINITION EXIT SELL ******/
    /*-----------------------------------------------------------------------------------*/
    
    bool exitSell = false ;
    
    if( IsFirstTick_HTF == true )
    {       

        //-- Note in TM_SHORT ; short-only trade, the exit sell signal exists
        //-- This section should contain techincal definition on technical exit signal
        //-- without considering any ticket !
        //-- The closing should be "CLOSE ALL OPEN POSITION"
        
        exitSell = ( 
                  macd_HTF_exit_hist_1  > 0 
              &&  macd_HTF_exit_hist_X <= 0
                  );    //-- A cross down from negative_sign to positive_sign

    }


    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\
    * Notes:
    * --------------
    * On TRAILING STOP CALCULATION, refer to 
    *   C:\Users\Hendy\AppData\Roaming\MetaQuotes\Terminal\50CA3DFB510CC5A8F28B48D1BF2A5702\..
    *   MQL4\Experts\MVTS_3_ATRTrailStop 1.04.mq4
    *
    * Tips:
    * --------------
    * Trailing stop can be on HTF, MTF, or LTF.
    * use IsFirstTick_HTF / IsFirstTick_MTF / IsFirstTick_LTF and ATR value relevant to its timeframe
    * and Low[1] or High[1] from the respective timeframe.
    * The Low[] or the High[] depends on timeframe of the *current chart*
    * To access Low[] or the High[] from different timeframe use iLow() and iHigh() function    
    * 
    \~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    
     
     

    /*-----------------------------------------------------------------------------------*/
    /****** EXECUTION - EXIT SELL ******/
    /*-----------------------------------------------------------------------------------*/     

    if( IsFirstTick_HTF && exitSell && TradeMode == TM_SHORT )
     {

        //*****************//
        //*** DEBUGGING ***//
        //*****************//          
          // Print( 
            // "======== EXIT SELL == " , 
             // "MACDH(18,36,18)[1]: "  , DoubleToString( macd_HTF_exit_hist_1 , 5) , " / " ,
             // "MACDH(18,36,18)[2]: "  , DoubleToString( macd_HTF_exit_hist_X , 5)
            // );      
        //


        //-- The closing should be "CLOSE ALL OPEN POSITION" 
        //-- The logic below is still from older logic that close first position only
        //-- I want simpler logic to close **all open position** 
        
        EXIT_ALL_POSITIONS(
            closedByTechnicalAnalysis   ,
            comment_exit
            );
            
      }    




    /*-----------------------------------------------------------------------------------*/
    /****** JOURNALING ON EXIT BY TECHNICAL DECISION ******/
    /*-----------------------------------------------------------------------------------*/       
        //-- Reporting on trade closure by "Technical Decision"
        //-- "Technical Decision" is technical rules, either by indicator reading,
        //-- or, by deliberate Exclusion Zone
        
        // TRADING_JOURNAL_CLOSED_BYTECHNICAL( );


    /*-----------------------------------------------------------------------------------*/
    /****** JOURNALING ON EXIT BY STOP LOSS OR PROFIT TARGET ******/
    /*-----------------------------------------------------------------------------------*/        
        // EXIT_BY_STOP_OR_TARGET( );


        
        
        
        



    /***********************************************************************************************/
    /***   ENTRY MANAGEMENT   ***/
    /***********************************************************************************************/   

 
 
    //+---------------------------------------------------------------------------------------------+
    //| ENTRY BUY BY TRADING SYSTEM TECHNICAL RULE                                                  |
    //+---------------------------------------------------------------------------------------------+
  
  
  
    /*-----------------------------------------------------------------------------------*/
    /****** SETUP AND TRIGGER ******/
    /*-----------------------------------------------------------------------------------*/
    
    //-- Every day, zero in daily entry limit back to zero
    if (IsFirstTick_HTF)
    {
      DailyCountEntry = 0 ;
    }
    
    
  
    bool triggerBuy = false ;
    if(
          // HTF-- SETUP        
          // (sma_HTF_drift_1 > sma_HTF_drift_X) &&             // SMA drift rule
              (macd_HTF_entry_hist_1 > macd_HTF_entry_hist_X)   // MACDH tick direction rule
          &&  (rsi3_HTF_cock_UP)                                // RSI3 HTF is cocked up 
          &&  (TradeMode == TM_LONG )
        )    
    
    
    //-- Powertool 4 uses Weekly Bar
    //-- Weekly bar is the main direction for long.
    //-- SMA drift rule for D1 may be redundant
    //-- Or, even we use RSI(3,D1) "pointing up" as setup,  
    //-- because the Weekly already guide the trend direction
    

    { // Setup
      
      
        //*****************//
        //*** DEBUGGING ***//
        //*****************//
        if( IsFirstTick_HTF )
          {
            Print( ""
                // "*** HTF uptick: " , 
                // "SMA(5) = "          ,     DoubleToString( sma_HTF_drift_1 , 4)         , " / " ,
                // "RSI(3) D1 [1]= "    ,     DoubleToString( rsi3_HTF_1 , 2 )             , " / " ,
                // "RSI(3) D1 [2]= "    ,     DoubleToString( rsi3_HTF_2 , 2 )             , " / " ,
               // //"MACDH(12,26,9)[1]: "   ,  DoubleToString( macd_HTF_entry_hist_1 , 5)  , " / " ,
               // //"MACDH(12,26,9)[2]: "   ,  DoubleToString( macd_HTF_entry_hist_X , 5)  , " / " ,
                // "MACDH(18,36,18)[1]: "  ,  DoubleToString( macd_HTF_exit_hist_1 , 5)    , " / " ,
                // "MACDH(18,36,18)[2]: "  ,  DoubleToString( macd_HTF_exit_hist_X , 5)
              );
          }   // End //*** DEBUGGING ***//




        if(// MTF SETUP
              rsi_MTF_fast_1 < 40                              // RSI is "dip"
          )
          {          

            if(
                  (lrco_LTF_2slow_2 < bb_LTF_channel2_lower_2) &&   // slow LR under lower bollinger band 
                  (lrco_LTF_1fast_1 > lrco_LTF_2slow_1) &&        // fast lr crosses slow lr
                  (lrco_LTF_1fast_2 <= lrco_LTF_2slow_2) &&       // fast lr touches or crosses slow lr
                  (lrco_LTF_1fast_1 > lrco_LTF_1fast_2)           // fast lr turn up          
              )
              {
                // LTF TRIGGER
                triggerBuy = true ;
                EntrySignalCountBuy++ ;
                
                
                // Draw Up arrow
                DrawArrowUp("Up"+Bars , Low[1]-10*Point , clrYellow );
                
                Print("");    //-- allow one row above
                Print(  "[OnTick]: " ,
                  "*** TRIGGER BUY****" , " " ,
                  EntrySignalCountBuy
                  );
                

              //*****************//
              //*** DEBUGGING ***//
              //*****************//
              //if( IsFirstTick_MTF )
                //{
                  Print ( ""
                        // "[OnTick]: " ,
                        // "---RSI MTF dip under 40: " , 
                        // "RSI(6): " , DoubleToStr(rsi_MTF_fast_1 , 4) , " / " ,
                        // "RSI(9): " , DoubleToStr(rsi_MTF_slow_1 , 4)
                     );              
                //} // End //*** DEBUGGING ***//
                
                              
                Print( ""                
                  // "[OnTick]: " ,
                  // "At Trigger LTF: " ,
                  // "BB Upper: "  , DoubleToStr(bb_LTF_channel1_upper_2, 6 ) , " / " ,
                  // "BB Lower: "  , DoubleToStr(bb_LTF_channel2_lower_2, 6) , " / " ,
                  // "LR(10)[1]: "    , DoubleToStr(lrco_LTF_1fast_1 , 5) , " / " ,
                  // "LR(30)[1]: "    , DoubleToStr(lrco_LTF_2slow_1 , 5) , " / " ,
                  // "LR(10)[2]: "    , DoubleToStr(lrco_LTF_1fast_2 , 5) , " / " ,
                  // "LR(30)[2]: "    , DoubleToStr(lrco_LTF_2slow_2 , 5)                                  
                );

                  
              }
          
          
          }
        
    } 

    // End Setup and Trigger BUY
    
      
      //*****************//
      //*** DEBUGGING ***//
      //*****************//      
      if( IsFirstTick_HTF )
      {
        // Print("[OnTick]: " ,              
            // "ExclZone_In: " , BoolToStr(ExclZone_In)
             // );
      }
      
  
  
  /*-----------------------------------------------------------------------------------*/
  /****** EXECUTION - ENTRY ******/
  /*-----------------------------------------------------------------------------------*/  
  
  if(
      CalculateCurrentOrders( Symbol() ) < 3 
        && (!ExclZone_In) 
        && (EntrySignalCountBuy <= EntrySignalCountThreshold) 
        && (TradeMode == TM_LONG )
        && triggerBuy        
    )       
  {
      
    /*-----------------------------------------------------------------------------------*/
    /****** EXECUTE_ENTRY_BUY ******/
    /*-----------------------------------------------------------------------------------*/



    EXECUTE_ENTRY_BUY_P1( 
                   atr_LTF_36bar_1 , 
                   closedByTechnicalAnalysis ,
                   flag_P1_OrderOpen ,
                   ticket_P1 
                   // MAEPips ,
                   // MFEPips ,
                   // RMult_Max ,
                   // RMult_Final
            );      
    //-- plannedTarget_P1 is used for plannedTarget_P2 and plannedTarget_P3
      
      
      //-- The following is to add more position with pyramiding
      
      EXECUTE_ENTRY_BUY_P2(
                  atr_LTF_36bar_1             ,
                  closedByTechnicalAnalysis   ,
                  flag_P2_OrderOpen           ,
                  ticket_P2
            );
      
      EXECUTE_ENTRY_BUY_P3(
                  atr_LTF_36bar_1             ,
                  closedByTechnicalAnalysis   ,
                  flag_P3_OrderOpen           ,
                  ticket_P3
            );
      
  }
  
  
  
  
  
  
 
    //+---------------------------------------------------------------------------------------------+
    //| ENTRY SELL BY TRADING SYSTEM TECHNICAL RULE                                                 |
    //+---------------------------------------------------------------------------------------------+
  

  
    /*-----------------------------------------------------------------------------------*/
    /****** SETUP AND TRIGGER ******/
    /*-----------------------------------------------------------------------------------*/
    
    bool triggerSell = false ;
    if(
          // HTF SETUP        
          // (sma_HTF_drift_1 < sma_HTF_drift_X) &&              // SMA drift rule
              (macd_HTF_entry_hist_1 < macd_HTF_entry_hist_X)     // MACDH tick direction rule
          &&  (TradeMode == TM_SHORT )
        )    
    
    
    //-- Powertool 4 uses Weekly Bar
    //-- Weekly bar is the main direction for short-ing.
    //-- SMA drift rule for D1 may be redundant
    //-- Or, even we use RSI(3,D1) "pointing down" as setup,  
    //-- because the Weekly already guide the trend direction
    

      { // Setup

      
        //*****************//
        //*** DEBUGGING ***//
        //*****************//
        if( IsFirstTick_HTF )
          {
            Print( "[OnTick]: " ,
              "*** HTF downtick: " , 
               "SMA(5) = "         , DoubleToString( sma_HTF_drift_1 , 4)         , " / " ,
               "MACDH(12,26,9)[1]: "   , DoubleToString( macd_HTF_entry_hist_1 , 5)  , " / " ,
               "MACDH(12,26,9)[2]: "   , DoubleToString( macd_HTF_entry_hist_X , 5)  , " / " ,
               "MACDH(18,36,18)[1]: "  , DoubleToString( macd_HTF_exit_hist_1 , 5) , " / " ,
               "MACDH(18,36,18)[2]: "  , DoubleToString( macd_HTF_exit_hist_X , 5)
              );
          }   // End //*** DEBUGGING ***//
      



        if(// MTF SETUP
              rsi_MTF_fast_1 > 60                            // RSI is "shoot up"
          )
          {        
          
            if(              
                (lrco_LTF_2slow_2 > bb_LTF_channel1_upper_2 ) &&  // slow LR above upper bollinger band 
                (lrco_LTF_1fast_1 < lrco_LTF_2slow_1) &&        // fast lr crosses slow lr
                (lrco_LTF_1fast_2 >= lrco_LTF_2slow_2) &&       // fast lr crosses slow lr
                (lrco_LTF_1fast_1 < lrco_LTF_1fast_2)           // fast lr turn down          
              )
              {
                  // LTF TRIGGER
                  triggerSell = true ;
                  EntrySignalCountSell++ ;
                  
                  
                  // Draw Down Arrow
                  DrawArrowDown("Dn"+Bars , High[1]+10*Point , clrRed );
                  
                  
                  Print("[OnTick]: " ,
                    "*** TRIGGER SELL****" , " " ,
                    EntrySignalCountSell
                    );

                    
              //*****************//
              //*** DEBUGGING ***//
              //*****************//
              // if( IsFirstTick_MTF )
                // {
                  Print ("[OnTick]: " ,
                        "---RSI shoot above 60: " , 
                        "RSI(6): " , DoubleToStr(rsi_MTF_fast_1 , 4) , " / " ,
                        "RSI(9): " , DoubleToStr(rsi_MTF_slow_1 , 4)
                     );              
                // } // End //*** DEBUGGING ***//
                    
                    
                Print("[OnTick]: " ,
                  "At Trigger: " ,
                  "BB Upper: "  , DoubleToStr(bb_LTF_channel1_upper_2, 6 ) , " / " ,
                  "BB Lower: "  , DoubleToStr(bb_LTF_channel2_lower_2, 6) , " / " ,
                  "LR(10)[1]: "    , DoubleToStr(lrco_LTF_1fast_1 , 5) , " / " ,
                  "LR(30)[1]: "    , DoubleToStr(lrco_LTF_2slow_1 , 5) , " / " ,
                  "LR(10)[2]: "    , DoubleToStr(lrco_LTF_1fast_2 , 5) , " / " ,
                  "LR(30)[2]: "    , DoubleToStr(lrco_LTF_2slow_2 , 5)                 
                );


              }


          } 
        
      } 
      else
      {
         EntrySignalCountSell = 0;
      }
      // End Setup and Trigger SELL
    
    
  
  
  /*-----------------------------------------------------------------------------------*/
  /****** EXECUTION ******/
  /*-----------------------------------------------------------------------------------*/
  
  if(
      CalculateCurrentOrders( Symbol() ) < 3
        && (!ExclZone_In) 
        && (EntrySignalCountSell <= EntrySignalCountThreshold)  
        && (TradeMode == TM_SHORT )
        && triggerSell
    )       
    {
      
    /*-----------------------------------------------------------------------------------*/
    /****** EXECUTE_ENTRY_SELL ******/
    /*-----------------------------------------------------------------------------------*/
            
      // EXECUTE_ENTRY_SELL_P1( 
                   // atr_LTF_36bar_1 , 
                   // closedByTechnicalAnalysis ,
                   // flag_P1_OrderOpen ,
                   // ticket_P1 ,
                   // MAEPips ,
                   // MFEPips ,
                   // RMult_Max ,
                   // RMult_Final
           // );      
           
      
      //-- The following is to add more position with pyramiding
      
      // EXECUTE_ENTRY_SELL_P2();
      
      // EXECUTE_ENTRY_SELL_P3();
      
    }  
  
   
   
   
   
   
   
  //+-------------------------------------------------------------------------------------------------+
  //| Reporting on First Tick HTF                                                                      |
  //+-------------------------------------------------------------------------------------------------+
   
  //-- Refer to [MVTS_4_HFLF_Model_A.mq4]




    
    /***********************************************************************************************/
    /***   ENDING BLOCK OF ONTICK()   ***/
    /***********************************************************************************************/

    // LAST BLOCK - TTF 
    TTF_Barname_Prev = TTF_Barname_Curr ;
    
    // LAST BLOCK - HTF
    HTF_Barname_Prev = HTF_Barname_Curr ;
    
    
    // LAST BLOCK - MTF
    MTF_Barname_Prev = MTF_Barname_Curr ;

   
    // LAST BLOCK - LTF
    LTF_Barname_Prev = LTF_Barname_Curr ;   
   
   
 
  }     // *******   End of OnTick()   *******







//+*******************************************************************************************************************+

//+*******************************************************************************************************************+


