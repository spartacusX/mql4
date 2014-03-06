//+------------------------------------------------------------------+
//|                                                        hello.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"


#define MAGICMA 19830716

//extern double STOPLOSS = 0.050;
//extern double TAKEPROFIT = 80;
extern int SL_MIN = 100;
extern int TP_MIN = 110;
extern int INDEX = 1;
extern int INDEX_MAX = 4;
extern double startlots = 0.2;
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders()
  {
   int buys=0,sells=0;
//----
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) 
         break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//---- return orders volume
   if(buys>0) 
      return(buys);
   
   if (sells>0)
      return (-sells);
   
   return (0);
  }

//+------------------------------------------------------------------+
//| Determin the start operation: OP_SELL or OP_BUY                                           |
//+------------------------------------------------------------------+  
int startOperation()
{
   if(iOpen(Symbol(), PERIOD_M5, 1) > iOpen(Symbol(), PERIOD_M5, 2))
      return (OP_BUY);   
   else if(iOpen(Symbol(), PERIOD_M5, 1) < iOpen(Symbol(), PERIOD_M5, 2))
      return (OP_SELL);
   else
   {
      if(iOpen(Symbol(), PERIOD_M5, 0) > iOpen(Symbol(), PERIOD_M5, 1))
         return (OP_BUY);
         
      return (OP_SELL);
   }     
}

//--------------------------------------------------------------------
// OrderSelect must be call before this method
//--------------------------------------------------------------------
bool MyOrderClose()
{
   bool res = true;
   
   if( OrderType() == OP_BUY )
      res = OrderClose(OrderTicket(), OrderLots(), Bid, 3, White);
   else
      res = OrderClose(OrderTicket(), OrderLots(), Ask, 3, White);
      
   if( res == false )
   {
      Print("Close order failed! Error = ", GetLastError());
      OrderPrint();
   }
   return (res);
}

//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
{
   //Print("Try to close the trade...");
   
   if(OrderSelect(0, SELECT_BY_POS, MODE_TRADES) == false)        
      return; // no order
      
   if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) 
      return; // not my order

   //Print("Profit = ", OrderProfit());
   //Print("Index = ", INDEX);
   //Print("LastLots = ", OrderLots());
   
   bool res = true;
   int LastOrderType = OrderType();
   double LastLots = OrderLots();
   if(OrderProfit() < -(SL_MIN*INDEX))
   {
      
      res = MyOrderClose();
      if(res == false)
      {
         Print("Close order failed in Loss!");
      }
      else
      {    
         if(INDEX < INDEX_MAX)
         {           
            INDEX = INDEX+1;
            Print("Index = ", INDEX);
            Print("LastOrderType = ", LastOrderType);
            int rc = 0;
            
            double lots = LastLots*2;
            //Print("lots = ", lots);
            if( LastOrderType == OP_BUY )
            {  
               rc = OrderSend(Symbol(), OP_SELL, lots, Bid, 3, 0, 0, "", MAGICMA, 0, Red);
            }
            else
            {
               rc = OrderSend(Symbol(), OP_BUY, lots, Ask, 3, 0, 0, "", MAGICMA, 0, Red);
            }
           
            if(rc == -1)
            {         
               Print("Send order failed. Error = ", GetLastError());
               INDEX = INDEX-1;
            }
            else
            {
               Print("New order. Doubled!");
            }
         }
         else
         {
            INDEX = 1;  //reset
            Print("Index has been reset!");
         }
      }
   }
   else if(OrderProfit() > TP_MIN*INDEX)
   {
      res = MyOrderClose();
      if(res == false)
      {
         Print("Close order failed in Profit!");
      }
      else
      {
         INDEX = 1;
         Print("Order closed with good profit!");
         if( LastOrderType == OP_BUY )
         {  
            rc = OrderSend(Symbol(), OP_BUY, startlots, Ask, 3, 0, 0, "", MAGICMA, 0, Red);
         }
         else
         {
            rc = OrderSend(Symbol(), OP_SELL, startlots, Bid, 3, 0, 0, "", MAGICMA, 0, Red);
         }
      }
   }
   else
   {
      //Print("No order has been closed!");
   }
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
   int res = -1;
   if(CalculateCurrentOrders() == 0)
   {
      Print("Try to open a trade...");
      int op = startOperation();
      
      int minSL = MarketInfo(Symbol(), MODE_STOPLEVEL);
      //double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
      //Print("lotstep = ", lotstep);
      
      if( op == OP_BUY )
         res = OrderSend(Symbol(), op, startlots, Ask, 3, 0, 0, "", MAGICMA, 0, Red);
      else
         res = OrderSend(Symbol(), op, startlots, Bid, 3, 0, 0, "", MAGICMA, 0, Red);
         
      if( res == -1 )
      {
         int err=GetLastError();
         Print("Send order failed... ´íÎó(",err,"): ");
         //if( err == 129 )
         Print("OrderSend: Operation = ", op, " Ask = ", Ask, " Bid = ", Bid);
      }
   }
   else
   {
      CheckForClose();
   }

   return(0);
  }
//+------------------------------------------------------------------+