#include <Trade\Trade.mqh>

#define STOCH_HIGH   80
#define STOCH_LOW    20

input double Volume           = 0.10;
input double StopLossPercent  = 0.03;

double K[], D[];
int Stoch;

int OnInit()
{
   ArraySetAsSeries(K, true);
   ArraySetAsSeries(D, true);
   Stoch = iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
   
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   ENUM_ORDER_TYPE order_type = NULL;
   CopyBuffer(Stoch, 0, 0, 4, K);
   CopyBuffer(Stoch, 1, 0, 4, D);
   CTrade trade;

   if(PositionsTotal() == 0){
      
      double sl = 0;
           
      MqlTick last_tick;      
      SymbolInfoTick(Symbol(), last_tick);
      
      if(K[0] > STOCH_HIGH && D[0] > STOCH_HIGH){
         if(isSell(K, D)){
            order_type = ORDER_TYPE_SELL;
            sl = iHigh(_Symbol, _Period, 1) * ( 1 + StopLossPercent );
         }   
      }
      
      if(K[0] < STOCH_LOW && D[0] < STOCH_LOW){
         if(isBuy(K, D)){
            order_type = ORDER_TYPE_BUY;
            sl = iLow(_Symbol, _Period, 1) * ( 1 - StopLossPercent );
         }
      }
      
      if(order_type != NULL){
         double price = order_type == ORDER_TYPE_BUY ? last_tick.ask : last_tick.bid;
         trade.PositionOpen(Symbol(), order_type, Volume, price, 0, 0, NULL);
         trade.PositionModify(Symbol(), sl, 0);
      }
      
   }
   
   if(PositionsTotal() == 1){
      if(order_type == ORDER_TYPE_BUY){
         if(isSell(K, D))
            order_type = NULL;
      }
      if(order_type == ORDER_TYPE_SELL){
         if(isBuy(K, D))
            order_type = NULL;
      }
      if(order_type == NULL)
         trade.PositionClosePartial(PositionGetTicket(0), Volume);
   }
   
}

bool isSell(double &K[], double &D[]){
   return K[3] > D[3] && K[2] > D[2] && K[1] < D[1];
}

bool isBuy(double &K[], double &D[]){
   return K[3] < D[3] && K[2] < D[2] && K[1] > D[1];
}
