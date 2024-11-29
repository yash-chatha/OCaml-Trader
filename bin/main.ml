open Finalproject.Stock
include ANSITerminal
module P = Finalproject.Portfolio
module RP = Finalproject.Rt_portfolio

let print_prices prices =
  List.iter (fun price -> Printf.printf "%.2f " price) prices;
  print_newline ()

let print_help () =
  print_endline "\nAvailable Commands:";
  print_endline "1. Buy stock - Allows you to buy shares of a specific stock.";
  print_endline "2. Sell stock - Allows you to sell shares of a specific stock.";
  print_endline
    "3. View portfolio - Displays your current portfolio summary, including \
     stock holdings and balance.";
  print_endline
    "4. Exit to earnings call (simulated mode) - Updates stock prices based on \
     simulated market conditions.";
  print_endline "5. Exit program - Closes the application.";
  print_endline "6. Help - Displays this help menu.\n";
  print_endline
    "Usage: Enter the number corresponding to the command you wish to execute.\n"

let print_help_rt () =
  print_endline "\nReal-Time Portfolio Commands:";
  print_endline "1. Buy stock - Buy shares of a stock in real-time.";
  print_endline "2. Sell stock - Sell shares of a stock in real-time.";
  print_endline
    "3. View portfolio - Displays your current portfolio summary, including \
     stock holdings and balance.";
  print_endline "4. Exit - Closes the real-time portfolio.";
  print_endline "5. Help - Displays this help menu.\n";
  print_endline
    "Usage: Enter the number corresponding to the command you wish to execute.\n"

(**[balance_input_loop] takes in a mode (simulated/real-time) and prompts users
   for portfolio balance input and loops until they provide a valid input.*)
let rec balance_input_loop mode =
  print_endline ("Enter initial balance for the " ^ mode ^ " portfolio:");
  let input = read_line () in
  try
    let balance = float_of_string input in
    balance (* Return the balance if the input is valid *)
  with _ ->
    print_endline "Invalid input - please enter a valid number.";
    balance_input_loop
      mode (* Call the function recursively if the input is invalid *)

(**[quantity_input_loop] takes in a mode (buy/sell) and prompts users to enter a
   quantity input and loops until they provide a valid input.*)
let rec quantity_input_loop mode =
  print_endline ("Enter quantity to " ^ mode ^ ":");
  let input = read_line () in
  try
    let quantity = int_of_string input in
    quantity
  with _ ->
    print_endline "Invalid input - please enter a valid integer.";
    quantity_input_loop mode

(**[print_yes_no] prints a nicely formatted (y/n) string using ANSITerminal.*)
let print_yes_no () =
  Stdlib.print_string "(";
  ANSITerminal.print_string
    [
      ANSITerminal.green;
      ANSITerminal.on_black;
      ANSITerminal.Bold;
      ANSITerminal.Underlined;
    ]
    "y";
  Stdlib.print_string "/";
  ANSITerminal.print_string
    [
      ANSITerminal.red;
      ANSITerminal.on_black;
      ANSITerminal.Bold;
      ANSITerminal.Underlined;
    ]
    "n";
  Stdlib.print_string ") \n"

let print_num_enclosed num color =
  Stdlib.print_string "(";
  ANSITerminal.print_string
    [ color; ANSITerminal.on_black; ANSITerminal.Bold; ANSITerminal.Underlined ]
    num;
  Stdlib.print_string ")"

(**[purchase_loop] takes in a portfolio and prompts users to enter a stock
   ticker to buy and loops until they provide a valid input.*)
let rec purchase_loop portfolio =
  print_endline "Enter stock ticker to buy: ";
  let stock_name = String.uppercase_ascii (read_line ()) in
  let quantity = quantity_input_loop "buy" in
  Printf.printf "Are you sure you want to buy %d shares of %s? " quantity
    stock_name;
  print_yes_no ();
  (*this is all setup*)
  let input = read_line () in
  if String.lowercase_ascii input = "y" then (
    try
      match Lwt_main.run (RP.buy_stock !portfolio stock_name quantity) with
      | Some updated_portfolio ->
          portfolio := updated_portfolio;
          Printf.printf "Bought %d shares of %s\n" quantity stock_name
      | None ->
          print_endline "Purchase failed. Check balance or stock availability."
    with _ ->
      print_endline ("Could not find " ^ stock_name ^ ". Please try again.");
      purchase_loop portfolio)
  else print_endline "Purchase canceled."

let () =
  ANSITerminal.print_string
    [
      ANSITerminal.cyan;
      ANSITerminal.on_black;
      ANSITerminal.Blink;
      ANSITerminal.Inverse;
      ANSITerminal.Bold;
    ]
    "\nWelcome to the Stock Query Interface!\n\n";
  (* Portfolio functionality starts here *)
  Stdlib.print_string "Would you like to create a portfolio? ";
  print_yes_no ();
  if String.lowercase_ascii (read_line ()) = "y" then (
    Stdlib.print_string "Do you want to create a ";
    print_num_enclosed "1" ANSITerminal.yellow;
    Stdlib.print_string " simulated portfolio or a ";
    print_num_enclosed "2" ANSITerminal.blue;
    Stdlib.print_string " real-time portfolio? ";
    Stdlib.print_string "(";
    ANSITerminal.print_string
      [
        ANSITerminal.yellow;
        ANSITerminal.on_black;
        ANSITerminal.Bold;
        ANSITerminal.Underlined;
      ]
      "1";
    Stdlib.print_string "/";
    ANSITerminal.print_string
      [
        ANSITerminal.blue;
        ANSITerminal.on_black;
        ANSITerminal.Bold;
        ANSITerminal.Underlined;
      ]
      "2";
    Stdlib.print_string ") \n";
    match read_line () with
    | "1" ->
        (* Simulated portfolio *)
        print_endline
          "Please enter the filename of the stock data (e.g., data/stocks.csv):";
        let filename = read_line () in
        let stock_data =
          try read_csv filename
          with _ ->
            print_endline "Error - file could not be found.";
            exit 0
        in

        print_endline "Enter a stock name to get prices:";
        let stock_name = String.lowercase_ascii (read_line ()) in

        (try
           let prices = get_prices stock_name stock_data in
           print_endline
             ("Prices for " ^ String.capitalize_ascii stock_name ^ ":");
           print_prices prices
         with
        | Failure msg -> print_endline ("Error: " ^ msg)
        | Not_found -> print_endline "Stock not found.");

        let new_stocks =
          List.map
            (let rand = Random.int 10 in
             let pattern =
               if rand < 2 then "low" else if rand < 7 then "mid" else "high"
             in
             update_prices pattern)
            stock_data
        in
        print_endline "";
        List.iter
          (fun x ->
            ANSITerminal.print_string
              [
                ANSITerminal.magenta;
                ANSITerminal.on_black;
                ANSITerminal.Bold;
                ANSITerminal.Underlined;
              ]
              ((x |> to_float |> fst |> String.capitalize_ascii) ^ " Stock:");
            Stdlib.print_string " ";
            x |> to_float |> snd |> print_prices)
          new_stocks;
        print_endline "";
        print_endline "Stock prices updated.";

        let initial_balance = balance_input_loop "simulated" in
        let portfolio = ref (P.create_portfolio initial_balance) in

        let rec portfolio_menu new_stocks =
          Stdlib.print_string "\nOptions: ";
          print_num_enclosed "1" ANSITerminal.yellow;
          Stdlib.print_string " Buy stock ";
          print_num_enclosed "2" ANSITerminal.blue;
          Stdlib.print_string " Sell stock ";
          print_num_enclosed "3" ANSITerminal.magenta;
          Stdlib.print_string " View portfolio ";
          print_num_enclosed "4" ANSITerminal.cyan;
          Stdlib.print_string " Exit to earnings call ";
          print_num_enclosed "5" ANSITerminal.white;
          Stdlib.print_string " Exit program ";
          print_num_enclosed "6" ANSITerminal.green;
          Stdlib.print_string " Help\n";
          match read_line () with
          | "1" ->
              print_endline "Enter stock name to buy:";
              let stock_name =
                try String.lowercase_ascii (read_line ())
                with _ ->
                  print_endline "Please try again with a valid stock name.";
                  exit 0
              in
              let quantity = quantity_input_loop "buy" in
              (* Confirmation step *)
              Printf.printf "Are you sure you want to buy %d shares of %s? "
                quantity
                (String.capitalize_ascii stock_name);
              print_yes_no ();
              if String.lowercase_ascii (read_line ()) = "y" then
                match P.buy_stock !portfolio stock_name quantity new_stocks with
                | Some updated_portfolio ->
                    portfolio := updated_portfolio;
                    Printf.printf "Bought %d shares of %s\n" quantity
                      (String.capitalize_ascii stock_name)
                | None ->
                    print_endline
                      "Purchase failed. Check balance or stock availability."
              else print_endline "Purchase canceled.";
              portfolio_menu new_stocks
          | "2" ->
              let stocks = P.get_stocks !portfolio in
              if stocks = [] then (
                print_endline "Error: You have no stocks to sell.";
                portfolio_menu new_stocks)
              else
                let stock_name =
                  match stocks with
                  | [ (name, _) ] ->
                      print_endline
                        ("Assuming stock to sell is: "
                        ^ String.capitalize_ascii name);
                      name
                  | _ ->
                      print_endline "Enter stock name to sell:";
                      String.lowercase_ascii (read_line ())
                in
                let quantity = quantity_input_loop "sell" in
                (* Confirmation step *)
                Printf.printf "Are you sure you want to sell %d shares of %s? "
                  quantity
                  (String.capitalize_ascii stock_name);
                print_yes_no ();
                if String.lowercase_ascii (read_line ()) = "y" then
                  match
                    P.sell_stock !portfolio stock_name quantity new_stocks
                  with
                  | Some updated_portfolio ->
                      portfolio := updated_portfolio;
                      Printf.printf "Sold %d shares of %s\n" quantity
                        (String.capitalize_ascii stock_name)
                  | None ->
                      print_endline
                        "Sale failed. Check if you have enough shares to sell \
                         or if the stock exists."
                else print_endline "Sale canceled.";
                portfolio_menu new_stocks
          | "3" ->
              let summary, balance =
                P.portfolio_summary !portfolio new_stocks
              in
              Printf.printf "Current balance: %.2f\n" balance;
              List.iter
                (fun (name, qty, value) ->
                  Printf.printf "Stock: %s, Quantity: %d, Value: %.2f\n" name
                    qty value)
                summary;
              let sum =
                List.fold_left
                  (fun acc (_, _, value) -> acc +. value)
                  0. summary
                +. balance
              in
              Printf.printf "Total value (balance + stock value): %.2f\n" sum;
              portfolio_menu new_stocks
          | "4" -> print_endline "Simulating earnings call."
          | "5" ->
              print_endline "Exiting program. Goodbye!";
              exit 0
          | "6" ->
              print_help ();
              portfolio_menu new_stocks
          | _ ->
              print_endline "Invalid option. Try again.";
              portfolio_menu new_stocks
        in

        let rec earnings_call stocks =
          let new_stocks =
            List.map
              (let rand = Random.int 10 in
               let pattern =
                 if rand < 2 then "low" else if rand < 7 then "mid" else "high"
               in
               update_prices pattern)
              stocks
          in
          print_endline "";
          List.iter
            (fun x ->
              ANSITerminal.print_string
                [
                  ANSITerminal.magenta;
                  ANSITerminal.on_black;
                  ANSITerminal.Bold;
                  ANSITerminal.Underlined;
                ]
                ((x |> to_float |> fst |> String.capitalize_ascii) ^ " Stock:");
              Stdlib.print_string " ";
              x |> to_float |> snd |> print_prices)
            new_stocks;
          print_endline "";
          print_endline "Stock prices updated.";
          (* Update portfolio or continue *)
          Stdlib.print_string
            "Would you like to update your portfolio, continue without \
             updating, or exit? ";
          Stdlib.print_string "(";
          ANSITerminal.print_string
            [
              ANSITerminal.yellow;
              ANSITerminal.on_black;
              ANSITerminal.Bold;
              ANSITerminal.Underlined;
            ]
            "1";
          Stdlib.print_string "/";
          ANSITerminal.print_string
            [
              ANSITerminal.blue;
              ANSITerminal.on_black;
              ANSITerminal.Bold;
              ANSITerminal.Underlined;
            ]
            "2";
          Stdlib.print_string "/";
          ANSITerminal.print_string
            [
              ANSITerminal.magenta;
              ANSITerminal.on_black;
              ANSITerminal.Bold;
              ANSITerminal.Underlined;
            ]
            "3";
          Stdlib.print_string ") \n";
          let input = read_line () in
          if input = "1" then (
            portfolio_menu new_stocks;
            earnings_call new_stocks)
          else if input = "2" then earnings_call new_stocks
          else exit 0
        in

        portfolio_menu new_stocks;
        earnings_call new_stocks
    | "2" ->
        (* Real-time portfolio *)
        let initial_balance = balance_input_loop "real-time" in
        let portfolio = ref (RP.create_rt_portfolio initial_balance) in

        let rec rt_portfolio_menu () =
          Stdlib.print_string "\nOptions: ";
          print_num_enclosed "1" ANSITerminal.yellow;
          Stdlib.print_string " Buy stock ";
          print_num_enclosed "2" ANSITerminal.blue;
          Stdlib.print_string " Sell stock ";
          print_num_enclosed "3" ANSITerminal.magenta;
          Stdlib.print_string " View portfolio ";
          print_num_enclosed "4" ANSITerminal.cyan;
          Stdlib.print_string " Exit ";
          print_num_enclosed "5" ANSITerminal.green;
          Stdlib.print_string " Help\n";
          match read_line () with
          | "1" ->
              purchase_loop portfolio;
              rt_portfolio_menu ()
          | "2" ->
              let stocks = RP.get_stocks !portfolio in
              if stocks = [] then (
                print_endline "Error: You have no stocks to sell.";
                rt_portfolio_menu ())
              else (
                print_endline "Enter stock ticker to sell:";
                let stock_name = String.uppercase_ascii (read_line ()) in
                let quantity = quantity_input_loop "sell" in
                (* Confirmation step *)
                Printf.printf "Are you sure you want to sell %d shares of %s? "
                  quantity stock_name;
                print_yes_no ();
                if String.lowercase_ascii (read_line ()) = "y" then
                  match
                    Lwt_main.run (RP.sell_stock !portfolio stock_name quantity)
                  with
                  | Some updated_portfolio ->
                      portfolio := updated_portfolio;
                      Printf.printf "Sold %d shares of %s\n" quantity stock_name
                  | None ->
                      print_endline
                        "Sale failed. Check if you have enough shares to sell \
                         or if the stock exists."
                else print_endline "Sale canceled.";
                rt_portfolio_menu ())
          | "3" ->
              let summary, balance =
                Lwt_main.run (RP.rt_portfolio_summary !portfolio)
              in
              Printf.printf "Current balance: %.2f\n" balance;
              List.iter
                (fun (name, qty, value) ->
                  Printf.printf "Stock: %s, Quantity: %d, Value: %.2f\n" name
                    qty value)
                summary;
              let sum =
                List.fold_left
                  (fun acc (_, _, value) -> acc +. value)
                  0. summary
                +. balance
              in
              Printf.printf "Total value (balance + stock value): %.2f\n" sum;
              rt_portfolio_menu ()
          | "4" ->
              print_endline "Exiting real-time portfolio. Goodbye!";
              exit 0
          | "5" ->
              (* Display help *)
              print_help_rt ();
              rt_portfolio_menu ()
          | _ ->
              print_endline "Invalid option. Try again.";
              rt_portfolio_menu ()
        in

        rt_portfolio_menu ()
    | _ -> print_endline "Invalid option. Please rerun and try again.")
  else print_endline "Portfolio creation skipped. Goodbye!"
