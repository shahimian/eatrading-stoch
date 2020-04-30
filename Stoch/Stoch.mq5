#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

#define BUFFER_NUMBER   3

#define STOCH_HIGH      70
#define STOCH_LOW       30

#define RSI_HIGH        70
#define RSI_LOW         30

input double Volume           = 0.10;
input double StopLossPercent  = 0.03;

double K[], D[], RsiValue[];
int Stoch, Rsi;
ENUM_ORDER_TYPE order_type = NULL;

int OnInit()
{
   ArraySetAsSeries(K, true);
   ArraySetAsSeries(D, true);
   ArraySetAsSeries(RsiValue, true);
   Stoch = iStochastic(Symbol(), Period(), 5, 3, 3, MODE_SMA, STO_LOWHIGH);
   Rsi = iRSI(Symbol(), Period(), 14, PRICE_CLOSE);
   
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   CopyBuffer(Stoch, MAIN_LINE, 0, BUFFER_NUMBER, K);
   CopyBuffer(Stoch, SIGNAL_LINE, 0, BUFFER_NUMBER, D);
   CopyBuffer(Rsi, MAIN_LINE, 0, BUFFER_NUMBER, RsiValue);
   
   CTrade trade;

   if(PositionsTotal() == 0){
      
      double sl = 0;
           
      MqlTick last_tick;
      SymbolInfoTick(Symbol(), last_tick);
      
      if(K[1] > STOCH_HIGH && D[1] > STOCH_HIGH && RsiValue[0] > RSI_HIGH){
         if(isSell(K, D)){
            order_type = ORDER_TYPE_SELL;
            sl = iHigh(Symbol(), Period(), 1) * ( 1 + StopLossPercent );
         }   
      }
      
      if(K[1] < STOCH_LOW && D[1] < STOCH_LOW && RsiValue[0] < RSI_LOW){
         if(isBuy(K, D)){
            order_type = ORDER_TYPE_BUY;
            sl = iLow(Symbol(), Period(), 1) * ( 1 - StopLossPercent );
         }
      }
      
      if(order_type != NULL){
         printf("Start Trade K[i]: %f %f %f D[i]: %f %f %f RSI0: %f", K[2], K[1], K[0], D[2], D[1], D[0], RsiValue[0]);
         double price = order_type == ORDER_TYPE_BUY ? last_tick.ask : last_tick.bid;
         trade.PositionOpen(Symbol(), order_type, Volume, price, 0, 0, NULL);
         trade.PositionModify(Symbol(), sl, 0);
         return;
      }
      
   }
   
   if(PositionsTotal() == 1){
      CPositionInfo info;
      info.SelectByIndex(0);
      if((info.PositionType() == POSITION_TYPE_BUY && isSell(K, D)) || (info.PositionType() == POSITION_TYPE_SELL && isBuy(K, D))){
         printf("Close Trade K[i]: %f %f %f D[i]: %f %f %f RSI0: %f", K[2], K[1], K[0], D[2], D[1], D[0], RsiValue[0]);      
         trade.PositionClosePartial(PositionGetTicket(0), Volume);
      }
   }
   
}

bool isSell(double &K[], double &D[]){
   return K[2] > D[2] && K[0] < D[0];
}

bool isBuy(double &K[], double &D[]){
   return K[2] < D[2] && K[0] > D[0];
}
