#property version "3.00"

#include <Trade\Trade.mqh>

// Creating an object of the tradeclass
CTrade trade;


// Defining variables
int handleTrendMaFast;
int handleTrendMaSlow;

int handleMaFast;
int handleMaMiddle;
int handleMaSlow;

int eamagic = 2;
double ealots = 0.05;

int OnInit(){

   // Set magic number for EA
   trade.SetExpertMagicNumber(eamagic);
     
   // Creating variables for the moving averages
   handleTrendMaFast = iMA(_Symbol, PERIOD_H1, 8, 0, MODE_EMA, PRICE_CLOSE);
   handleTrendMaSlow = iMA(_Symbol, PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE);
  
   handleMaFast = iMA(_Symbol, PERIOD_M5, 8, 0, MODE_EMA, PRICE_CLOSE);
   handleMaMiddle = iMA(_Symbol, PERIOD_M5, 13, 0, MODE_EMA, PRICE_CLOSE);
   handleMaSlow = iMA(_Symbol, PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE);

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){

}

void OnTick(){

   // Creating handler for the moving averages
   double maTrendFast[], maTrendSlow[];
   CopyBuffer(handleTrendMaFast, 0, 0, 1, maTrendFast);
   CopyBuffer(handleTrendMaSlow, 0, 0, 1, maTrendSlow);
   
   double maFast[], maMiddle[], maSlow[];
   CopyBuffer(handleMaFast, 0, 0, 1, maFast);
   CopyBuffer(handleMaMiddle, 0, 0, 1, maMiddle);
   CopyBuffer(handleMaSlow, 0, 0, 1, maSlow);

   // Recieve the current price for the symbol
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Use an integer value to identify the current direction
   int trendDirection = 0;
   
   // Checks if the MA-FAST value is GREATER than the MA-SLOW value AND if the bid-price is above/below the moving average.
   if(maTrendFast[0] > maTrendSlow[0] && bid > maTrendFast[0]){
      // If it is; trendDirection = 1 (It's an UPTREND)
      trendDirection = 1;
   }else if(maTrendFast[0] < maTrendSlow[0] && bid < maTrendFast[0]){
      // If it is not; trendDirection = -1 (It's a DOWNTREND)
      trendDirection = -1;
    }
    
    int positions = 0;
    // Loops through every position.Increment every time we find a new position
    for(int i = PositionsTotal()-1; i >= 0; i--){
      // Get the position index of the value 0
      ulong posTicket = PositionGetTicket(i);
      // Select a position if you provide the ticket as the parameter
      if(PositionSelectByTicket(posTicket)){
         // Check if the symbol is equal to the chart and the magic number
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == eamagic){
            positions++;
            
            // Checks if we have a buy position
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
               if(PositionGetDouble(POSITION_VOLUME) >= ealots){
                  
                  // First TP: Position open price + open price - first SL
                  double tp = PositionGetDouble(POSITION_PRICE_OPEN) + (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL));
                  
                  //If price reaches this mark:
                  if(bid >= tp){
                  
                     // Then we close half of the position
                     if(trade.PositionClosePartial(posTicket, NormalizeDouble(PositionGetDouble(POSITION_VOLUME)/2,2))){
                        // We move the SL. Calculate the new SL.
                        double sl = PositionGetDouble(POSITION_PRICE_OPEN);
                        // Round the value
                        sl = NormalizeDouble(sl, _Digits);
                        if(trade.PositionModify(posTicket, sl, 0)){                       
                        }
                     }
                  }
               }else{
               
                  // Finds the lowest of the last 3 candles
                  int lowest = iLowest(_Symbol, PERIOD_M5, MODE_LOW, 3,1);
                  
                  // Calculate the new SL
                  double sl = iLow(_Symbol, PERIOD_M5, lowest);
                  sl = NormalizeDouble(sl, _Digits);
                  
                  // Check if the new SL is greater than the position SL
                  if(sl > PositionGetDouble(POSITION_SL)){
                     if(trade.PositionModify(posTicket, sl, 0)){
                     }
                  }
               }
            // Checks if we have a sell position
            }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                  if(PositionGetDouble(POSITION_VOLUME) >= ealots){
                     double tp = PositionGetDouble(POSITION_PRICE_OPEN) - (PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN));
                  
                     if(bid <= tp){
                        if(trade.PositionClosePartial(posTicket, NormalizeDouble(PositionGetDouble(POSITION_VOLUME)/2,2))){
                           
                           double sl = PositionGetDouble(POSITION_PRICE_OPEN);
                           sl = NormalizeDouble(sl, _Digits);
                           if(trade.PositionModify(posTicket, sl, 0)){               
                           }
                        }
                     }            
               }else{
                  // Finds the highest of the last 3 candles
                  int highest = iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 3,1);
                  
                  // Calculate the new SL
                  double sl = iHigh(_Symbol, PERIOD_M5, highest);
                  sl = NormalizeDouble(sl, _Digits);
                  
                  // Check if the new SL is greater than the position SL
                  if(sl < PositionGetDouble(POSITION_SL)){
                     if(trade.PositionModify(posTicket, sl, 0)){
                     }
                  }
               }
            }         
         }
      }
    }
    
    
    int orders = 0;
    
    // Checks for the total amount of orders
    for(int i = OrdersTotal()-1; i >= 0; i--){
      
      // Get the position index of the value 0
      ulong orderTicket = OrderGetTicket(i);
      double candleClosePrice = iClose(_Symbol, PERIOD_M5, 1);
      if(OrderSelect(orderTicket)){
         
         // Order identifier:
         if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == eamagic){
            //if(OrderGetInteger(ORDER_TIME_SETUP) < TimeCurrent() - 10 * PeriodSeconds(PERIOD_M1)){
               //trade.OrderDelete(orderTicket);
            if(candleClosePrice > maSlow[0]) {
               trade.OrderDelete(orderTicket);
            }
            orders++;
         }
      }
    
    }
   // BUY STOP function
   // If direction is an UPTREND we can open a buyStop order
   if(trendDirection == 1){
      if(maFast[0] > maMiddle[0] && maMiddle[0] > maSlow[0]) {
         if(bid <= maFast[0]) {
            
            // If no other position is open
            if (positions + orders <= 0){
            
            // Returns an index of the highest price in a spesific timeframe
            int indexHighest = iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 5, 1);
            
            // Calculate the high price with the iHigh-function. Returns the price of the candle at a spesific index
            double highPrice = iHigh(_Symbol, PERIOD_M5, indexHighest);
            highPrice = NormalizeDouble(highPrice, _Digits);
            
            // Calculate the lowest price - 30 pips
            double sl = iLow(_Symbol, PERIOD_M5, 0) - 30 * _Point;
            sl = NormalizeDouble(sl, _Digits);  
            
            trade.BuyStop(ealots, highPrice, _Symbol, sl);
            }
         }
      }
      
   // SELL STOP function
   // If direction is an DOWNTREND we can open a sellStop order
   }else if(trendDirection == -1) {
      if(maFast[0] < maMiddle[0] && maMiddle[0] < maSlow[0]) {
         if(bid >= maFast[0]) {
            if (positions + orders <= 0) {
            int indexLowest = iLowest(_Symbol, PERIOD_M5, MODE_LOW, 5, 1);
            double lowestPrice = iLow(_Symbol, PERIOD_M5, indexLowest);
            lowestPrice = NormalizeDouble(lowestPrice, _Digits);
            
            // Calculate the highest price + 30 pips
            double sl = iHigh(_Symbol, PERIOD_M5, 0) + 30 * _Point;
            sl = NormalizeDouble(sl, _Digits);
            trade.SellStop(ealots, lowestPrice, _Symbol, sl);
            }

         }
      }

   }
   
   
   Comment("\nFast Trend Ma: ", DoubleToString(maTrendFast[0], _Digits),
           "\nSlow Trend Ma: ", DoubleToString(maTrendSlow[0], _Digits),
           "\nTrend Direction: ", trendDirection,
           "\n",
           "\nFast MA: ", DoubleToString(maFast[0], _Digits),
           "\nMiddle MA: ", DoubleToString(maMiddle[0], _Digits),
           "\nSlow MA: ", DoubleToString(maSlow[0], _Digits),
           "\nPositions: ", positions,
           "\nOrders: ", orders
           );
}
