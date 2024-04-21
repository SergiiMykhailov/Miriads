from firebase_functions import firestore_fn, https_fn

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore
import google.cloud.firestore
import time


MORALIS_API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJub25jZSI6IjI2OWIwMzI1LWViMjctNDA5Ni1iY2VjLTYxMGQ4YmJmYjRiYyIsIm9yZ0lkIjoiMzgyNDQyIiwidXNlcklkIjoiMzkyOTY0IiwidHlwZUlkIjoiMDU5MWQ5NzItZGU3OC00ZjNjLTllMTYtNzU4OGQ1NTJjMjg2IiwidHlwZSI6IlBST0pFQ1QiLCJpYXQiOjE3MTAyNDkzNjcsImV4cCI6NDg2NjAwOTM2N30.u0OgFrKWer9nuFq2cimZZfv4CNgeqeYlZxCEpWDHrSM"
MAX_REQUESTS_PER_BATCH = 50


initialize_app()


class WalletUpdadeInfo:
    def __init__(self, wallet_address, transactions_update_timestamp, balance_update_timestamp):
        self.wallet_address = wallet_address
        self.transactions_update_timestamp = transactions_update_timestamp
        self.balance_update_timestamp = balance_update_timestamp



    def __repr__(self):
        return f"WalletUpdateInfo(wallet_address={self.wallet_address}, transactions_update_timestamp={self.transactions_update_timestamp}, balance_update_timestamp={self.balance_update_timestamp})"



@https_fn.on_request()
def record_entry(request: https_fn.Request) -> https_fn.Response:
    user_id = request.args.get("user_id")
    wallet_id = request.args.get("wallet_id")
    domain = request.args.get("domain")
    session_id = request.args.get("session_id")
    if user_id is None or wallet_id is None or domain is None or session_id is None:
        return https_fn.Response(
            "Some of parameters: 'user_id'/'wallet_id'/'domain'/'session_id' are missing",
            status = 400
        )

    firestore_client: google.cloud.firestore.Client = firestore.client()

    current_timestamp = time.time()
    firestore_client \
        .collection("domains") \
        .document(domain) \
        .collection("visitors") \
        .document(user_id) \
        .set({"updated_at": current_timestamp})

    firestore_client \
        .collection("domains") \
        .document(domain) \
        .set({"updated_at": current_timestamp}, merge=True)

    session_data = {"wallet_id": wallet_id}
    utm_source = request.args.get("utm_source")
    utm_medium = request.args.get("utm_medium")
    utm_campaign = request.args.get("utm_campaign")

    if utm_source is not None:
        session_data["utm_source"] = utm_source
    if utm_medium is not None:
        session_data["utm_medium"] = utm_medium
    if utm_campaign is not None:
        session_data["utm_campaign"] = utm_campaign

    # Push the new message into Cloud Firestore using the Firebase Admin SDK.
    firestore_client \
        .collection("domains") \
        .document(domain) \
        .collection("visitors") \
        .document(user_id) \
        .collection("sessions") \
        .document(session_id) \
        .set(session_data)

    # Send back a message that we've successfully written the message
    return https_fn.Response("Record added.")



def load_all_wallets_from_visitors_sessions() -> set[str]:
    firestore_client: google.cloud.firestore.Client = firestore.client()

    domains = firestore_client.collection("domains").stream()

    wallets = set()

    for domain in domains:
        visitors = firestore_client \
            .collection("domains") \
            .document(domain.id) \
            .collection("visitors") \
            .stream()

        for visitor in visitors:
            sessions = firestore_client \
                .collection("domains") \
                .document(domain.id) \
                .collection("visitors") \
                .document(visitor.id) \
                .collection("sessions") \
                .stream()

            for session in sessions:
                session_data = session.to_dict()
                wallet_id = session_data["wallet_id"]

                wallets.add(wallet_id)

    return wallets



def load_all_existing_wallets_updates() -> [WalletUpdadeInfo]:
    firestore_client: google.cloud.firestore.Client = firestore.client()

    result = []

    wallets_collection = firestore_client.collection("wallets").stream()
    for wallet_document in wallets_collection:
        wallet_address = wallet_document.id

        wallet_data = wallet_document.to_dict()
        transactions_update_timestamp = wallet_data.get("transactions_updated_at")
        balance_update_timestamp = wallet_data.get("balance_updated_at")

        result.append(WalletUpdadeInfo(wallet_address, transactions_update_timestamp, balance_update_timestamp))

    return result



def install_moralis_if_needed() -> str:
    response = ""

    try:
        import moralis
    except ImportError:
        response += "\nInstalling Moralis SDK..."
        try:
            import pip
            pip.main(['install', 'moralis'])
            response += "\nMoralis SDK installation succeeded"
        except Exception as e:
            response += "\nMoralis SDK installation failed"

    return response



def update_transactions_of_wallets(wallets) -> str:
    response = ""

    try:
        firestore_client: google.cloud.firestore.Client = firestore.client()

        response += install_moralis_if_needed()
        from moralis import evm_api

        requests_count = 0

        for wallet in wallets:
            response += f"\n\n\n>>> BEGIN processing wallet [{wallet}]: \n"

            cursor = None

            while True:
                params = {
                    "chain": "eth",
                    "order": "DESC",
                    "address": wallet
                }

                response += f">>>>>> Handling cursor: [{cursor}]: \n"
                if cursor is not None and cursor.strip():
                    response += f">>>>>>>>> Cursor is set \n"
                    params["cursor"] = cursor
                response += f"<<<<<< Handling cursor: [{cursor}]: \n"

                response += f">>>>>> Fetching transactions history... \n"
                wallet_history_response = evm_api.wallets.get_wallet_history(
                    api_key=MORALIS_API_KEY,
                    params=params,
                )
                response += f"<<<<<< Fetching transactions history... \n"
                response += f"\n\n\nTransactions fetch result for wallet [{wallet}]: \n" + str(wallet_history_response)

                requests_count += 1

                cursor = wallet_history_response.get("cursor")
                response += f"\nCursor: [{cursor}]:"

                transactions_data = wallet_history_response["result"]
                for transaction_entry in transactions_data:
                    transaction_hash = transaction_entry["hash"]

                    firestore_client \
                        .collection("wallets") \
                        .document(wallet) \
                        .collection("transactions") \
                        .document(transaction_hash) \
                        .set(transaction_entry)

                if cursor is None or not cursor.strip() or requests_count >= MAX_REQUESTS_PER_BATCH:
                    current_timestamp = time.time()
                    firestore_client \
                        .collection("wallets") \
                        .document(wallet) \
                        .set({"transactions_updated_at": current_timestamp}, merge=True)
                    break

            response += f"\n\n\n<<< END processing wallet [{wallet}]: \n"
    except Exception as e:
        response += "\nException occurred: " + str(e)

    return response
    
    
    
def find_fresh_wallets(all_available_wallets: [str], existing_wallets: [WalletUpdadeInfo]) -> [str]:
    result = []

    for wallet in all_available_wallets:
        wallet_found = False

        for existing_wallet in existing_wallets:
            if existing_wallet.wallet_address.lower() == wallet.lower():
                wallet_found = True
                break

        if not wallet_found:
            result.append(wallet)

    return result



@https_fn.on_request()
def update_wallets_transactions(request: https_fn.Request) -> https_fn.Response:
    response = ""

    try:
        wallets = load_all_wallets_from_visitors_sessions()
        response += "\nAll wallets: " + str(wallets) + "\n"

        existing_wallets_updates = load_all_existing_wallets_updates()
        fresh_wallets = find_fresh_wallets(wallets, existing_wallets_updates)

        response += "\nFresh wallets: " + str(fresh_wallets) + "\n"
        response += update_transactions_of_wallets(fresh_wallets)

        existing_wallets_sorted = sorted(
            existing_wallets_updates,
            key = lambda element: element.transactions_update_timestamp
        )
        response += "\nWallets sorted by transactions update time: " + str(existing_wallets_sorted) + "\n"

        existing_wallets_addresses_sorted = [element.wallet_address for element in existing_wallets_sorted]
        response += "\nWallets addresses sorted by transactions update time: " + str(existing_wallets_addresses_sorted) + "\n"

        response += update_transactions_of_wallets(existing_wallets_addresses_sorted)

        response += "\n\n\nWallets updated"
    except Exception as e:
        response += "\nException occurred: " + str(e)

    response = "<pre>\n\n" + response + "\n\n</pre>\n"

    return https_fn.Response(response)



def update_balance_of_wallets(wallets) -> str:
    response = ""

    try:
        firestore_client: google.cloud.firestore.Client = firestore.client()

        requests_count = 0

        response += install_moralis_if_needed()
        from moralis import evm_api

        for wallet in wallets:
            response += f"\n\n\n>>> BEGIN processing wallet [{wallet}]: \n"

            params = {
                "exclude_spam": True,
                "exclude_unverified_contracts": True,
                "address": wallet
            }

            wallet_net_worth_in_usd_response = evm_api.wallets.get_wallet_net_worth(
                api_key=MORALIS_API_KEY,
                params=params,
            )

            current_timestamp = time.time()
            firestore_client \
                .collection("wallets") \
                .document(wallet) \
                .collection("balance_history") \
                .document(str(current_timestamp)) \
                .set(wallet_net_worth_in_usd_response, merge=True)

            firestore_client \
                .collection("wallets") \
                .document(wallet) \
                .set({"balance_updated_at": current_timestamp}, merge=True)

            response += f"\n\n\nNet-worth fetch result for wallet [{wallet}]: \n" + str(wallet_net_worth_in_usd_response)
            response += f"\n\n\n<<< END processing wallet [{wallet}]: \n"

            requests_count += 1
            if requests_count >= MAX_REQUESTS_PER_BATCH:
                response += f"\nExceeded max requests count per batch ({MAX_REQUESTS_PER_BATCH}). Terminating...\n"
                return response
    except Exception as e:
        response += "\nException occurred: " + str(e)

    return response



@https_fn.on_request()
def update_wallets_balance(request: https_fn.Request) -> https_fn.Response:
    response = ""

    try:
        wallets = load_all_wallets_from_visitors_sessions()
        response += "\nAll wallets: " + str(wallets) + "\n"

        existing_wallets_updates = load_all_existing_wallets_updates()
        fresh_wallets = find_fresh_wallets(wallets, existing_wallets_updates)

        response += "\nFresh wallets: " + str(fresh_wallets) + "\n"
        response += update_balance_of_wallets(fresh_wallets)

        existing_wallets_sorted = sorted(
            existing_wallets_updates,
            key = lambda element: element.balance_update_timestamp
        )
        response += "\nWallets sorted by balance update time: " + str(existing_wallets_sorted) + "\n"

        existing_wallets_addresses_sorted = [element.wallet_address for element in existing_wallets_sorted]
        response += "\nWallets addresses sorted by balance update time: " + str(existing_wallets_addresses_sorted) + "\n"

        response += update_balance_of_wallets(existing_wallets_addresses_sorted)

        response += "\n\n\nWallets updated"
    except Exception as e:
        response += "\nException occurred: " + str(e)

    response = "<pre>\n\n" + response + "\n\n</pre>\n"

    return https_fn.Response(response)



def update_statistics_of_wallets(wallets) -> str:
    response = ""

    try:
        firestore_client: google.cloud.firestore.Client = firestore.client()

        requests_count = 0

        response += install_moralis_if_needed()
        from moralis import evm_api

        for wallet in wallets:
            response += f"\n\n\n>>> BEGIN processing wallet [{wallet}]: \n"

            params = {
              "chain": "eth",
              "address": wallet
            }

            wallet_statistics_response = evm_api.wallets.get_wallet_stats(
              api_key=MORALIS_API_KEY,
              params=params,
            )

            current_timestamp = time.time()
            firestore_client \
                .collection("wallets") \
                .document(wallet) \
                .collection("statistics_history") \
                .document(str(current_timestamp)) \
                .set(wallet_statistics_response, merge=True)

            firestore_client \
                .collection("wallets") \
                .document(wallet) \
                .set({"statistics_updated_at": current_timestamp}, merge=True)

            response += f"\n\n\nStatistics fetch result for wallet [{wallet}]: \n" + str(wallet_statistics_response)
            response += f"\n\n\n<<< END processing wallet [{wallet}]: \n"

            requests_count += 1
            if requests_count >= MAX_REQUESTS_PER_BATCH:
                response += f"\nExceeded max requests count per batch ({MAX_REQUESTS_PER_BATCH}). Terminating...\n"
                return response

    except Exception as e:
            response += "\nException occurred: " + str(e)

    return response



@https_fn.on_request()
def update_wallets_statistics(request: https_fn.Request) -> https_fn.Response:
    response = ""

    try:
        wallets = load_all_wallets_from_visitors_sessions()
        response += "\nAll wallets: " + str(wallets) + "\n"

        existing_wallets_updates = load_all_existing_wallets_updates()
        fresh_wallets = find_fresh_wallets(wallets, existing_wallets_updates)

        response += "\nFresh wallets: " + str(fresh_wallets) + "\n"
        response += update_statistics_of_wallets(fresh_wallets)

        existing_wallets_sorted = sorted(
            existing_wallets_updates,
            key = lambda element: element.balance_update_timestamp
        )
        response += "\nWallets sorted by statistics update time: " + str(existing_wallets_sorted) + "\n"

        existing_wallets_addresses_sorted = [element.wallet_address for element in existing_wallets_sorted]
        response += "\nWallets addresses sorted by statistics update time: " + str(existing_wallets_addresses_sorted) + "\n"

        response += update_statistics_of_wallets(existing_wallets_addresses_sorted)

        response += "\n\n\nWallets updated"
    except Exception as e:
        response += "\nException occurred: " + str(e)

    response = "<pre>\n\n" + response + "\n\n</pre>\n"

    return https_fn.Response(response)