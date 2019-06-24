%%%-------------------------------------------------------------------
%%% @author Loveshant
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Jun 2019 02:11
%%%-------------------------------------------------------------------
-module(money).
-author("Loveshant").


-export([loan_queries/1, start/0, spawner_for_bank/2, start_loan_request/1, start_request_from_customer/2]).
-define(PROCESS_TIMEOUT,5000).

loan_queries(Bank) ->
  receive
    {Bank, From, Request_amount, P_id} ->
      [{_, Money}] = ets:lookup(bank_threads,Bank),
      RemainingMoney = Money - Request_amount,
      if
        RemainingMoney >= 0 -> ets:insert(bank_threads, {Bank, RemainingMoney}),
          io:format("\n~w approves a loan of ~w dollar(s) from ~w.~n",[Bank, Request_amount, From]),
          P_id ! {response, From, 1, Request_amount, Bank};
        RemainingMoney < 0 -> io:format("\n~w denies a loan of ~w dollar(s) from ~w.~n",[Bank, Request_amount, From]),
          P_id ! {response, From, 0, Request_amount, Bank}
      end,
      loan_queries(Bank)
  after ?PROCESS_TIMEOUT ->
    [{_, Money}] = ets:lookup(bank_threads,Bank),
    io:format("\n~w has ~w dollar(s) remaining.~n",[Bank,Money]),
    exit(normal)
  end.

start() ->
  {ok, Details} = file:consult("banks.txt"),
  io:format("~s.~n",["*** Banks threads to be made ***"]),
  [io:format("~w: ~w.~n",[Bank,Money]) || {Bank,Money} <- Details],
  io:format("\n"),
  Bank_map = maps:from_list(Details),
  Bank_List = maps:keys(Bank_map),
  ets:new(bank_threads, [named_table, public, set, {keypos, 1}]),
  ets:new(bank_id, [named_table, public, set, {keypos, 1}]),
  [spawner_for_bank(Bank, Money)|| {Bank,Money} <- Details],

  {ok, CustomerDetails} = file:consult("customers.txt"),
  io:format("~s.~n",["*** Customers threads to be made ***"]),
  [io:format("~w: ~w.~n",[CustomerName,CustomerMoney]) || {CustomerName,CustomerMoney} <- CustomerDetails],
  io:format("\n"),

  ets:new(customer_threads, [named_table, public, set, {keypos, 1}]),
  ets:new(customer_original_data, [named_table, public, set, {keypos, 1}]),
  ets:new(customer_id, [named_table, public, set, {keypos, 1}]),
  ets:new(customer_bank_list, [named_table, public, set, {keypos, 1}]),
  [spawner_for_customer(CustomerName,CustomerMoney,Bank_List) || {CustomerName,CustomerMoney} <- CustomerDetails].


% function to create banks threads
spawner_for_bank(Bank, Money) ->
  ets:insert(bank_threads, {Bank, Money}),
  P_id = spawn(fun() -> loan_queries(Bank) end),
  ets:insert(bank_id, {Bank, P_id}).

% function to create customers threads
spawner_for_customer(CustomerName,CustomerMoney, Bank_List) ->
  ets:insert(customer_threads, {CustomerName,CustomerMoney}),
  ets:insert(customer_original_data, {CustomerName,CustomerMoney}),
  P_id = spawn(fun() -> start_request_from_customer(CustomerName, Bank_List) end),
  ets:insert(customer_id, {CustomerName, P_id}).

start_request_from_customer(CustomerName, Bank_List) ->
  ets:insert(customer_bank_list, {CustomerName,Bank_List}),
  start_loan_request(CustomerName).

start_loan_request(CustomerName) ->
  [{_,CustomerRemainingLoanRequestAmount}] = ets:lookup(customer_threads, CustomerName),
  [{_,Bank_List}] = ets:lookup(customer_bank_list, CustomerName),
  Total_Available_Bank = length(Bank_List),
  if
    (CustomerRemainingLoanRequestAmount > 0) and (Total_Available_Bank > 0) ->
      %random bank and random amount
      Random_Bank_Location = rand:uniform(Total_Available_Bank),
      Bank = lists:nth(Random_Bank_Location, Bank_List),
      Random_Amount = rand:uniform(50),
      if
        CustomerRemainingLoanRequestAmount =< 50 -> Amount = CustomerRemainingLoanRequestAmount;
        true -> Amount = Random_Amount
      end,
      [{_,A}] = ets:lookup(bank_id, Bank),
      io:format("\n~w request a loan of ~w dollar(s) from ~w.~n",[CustomerName, Amount, Bank]),
      timer:sleep((rand:uniform(100)+10)),
      A ! {Bank, CustomerName, Amount, self()},
      loan_queries_response(CustomerName),
      start_loan_request(CustomerName);
    CustomerRemainingLoanRequestAmount =< 0 ->
      [{_,CustomerOriginalAmount}] = ets:lookup(customer_original_data, CustomerName),
      io:format("\n~w has reached the objective of ~w  dollar(s). Woo Hoo!~n",[CustomerName, CustomerOriginalAmount]),
      exit(normal);
    Total_Available_Bank =< 0 ->
      [{_,CustomerOriginalAmount}] = ets:lookup(customer_original_data, CustomerName),
      [{_,CustomerRemainingAmount}] = ets:lookup(customer_threads, CustomerName),
      AvailedAmount = CustomerOriginalAmount - CustomerRemainingAmount,
      io:format("\n~w was only able to borrow ~w  dollar(s). Boo Hoo!~n",[CustomerName, AvailedAmount]),
      exit(normal)
  end.

loan_queries_response(Customer) ->
  receive
    {response, Customer, Sanctioned, Amount, Bank} ->
      if
        Sanctioned == 1 ->
          [{_,CustomerRemainingLoanRequestAmount}] = ets:lookup(customer_threads, Customer),
          NewRemainingAmount = CustomerRemainingLoanRequestAmount - Amount,
          ets:insert(customer_threads, {Customer,NewRemainingAmount});
        Sanctioned == 0 ->
          [{_,Bank_List}] = ets:lookup(customer_bank_list, Customer),
          New_Bank_List = Bank_List-- [Bank],
          ets:insert(customer_bank_list, {Customer,New_Bank_List})
      end
  end.

