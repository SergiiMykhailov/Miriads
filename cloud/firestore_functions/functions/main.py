from firebase_functions import firestore_fn, https_fn

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore
import google.cloud.firestore
import time


MORALIS_API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJub25jZSI6IjI2OWIwMzI1LWViMjctNDA5Ni1iY2VjLTYxMGQ4YmJmYjRiYyIsIm9yZ0lkIjoiMzgyNDQyIiwidXNlcklkIjoiMzkyOTY0IiwidHlwZUlkIjoiMDU5MWQ5NzItZGU3OC00ZjNjLTllMTYtNzU4OGQ1NTJjMjg2IiwidHlwZSI6IlBST0pFQ1QiLCJpYXQiOjE3MTAyNDkzNjcsImV4cCI6NDg2NjAwOTM2N30.u0OgFrKWer9nuFq2cimZZfv4CNgeqeYlZxCEpWDHrSM"


initialize_app()


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

    start_timestamp = time.time()
    firestore_client \
        .collection("domains") \
        .document(domain) \
        .collection("visitors") \
        .document(user_id) \
        .set({"updated_at": start_timestamp})

    firestore_client \
        .collection("domains") \
        .document(domain) \
        .set({"updated_at": start_timestamp}, merge=True)

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



@https_fn.on_request()
def update_wallets_transactions(request: https_fn.Request) -> https_fn.Response:
    response = ""

    try:
        firestore_client: google.cloud.firestore.Client = firestore.client()
        start_timestamp = time.time()

        wallets = load_all_wallets_from_visitors_sessions()
        response += "\nAll wallets: " + str(wallets) + "\n"

        response += install_moralis_if_needed()
        from moralis import evm_api

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

                if cursor is None or not cursor.strip():
                    firestore_client \
                        .collection("wallets") \
                        .document(wallet) \
                        .set({"transactions_updated_at": start_timestamp}, merge=True)
                    break

            response += f"\n\n\n<<< END processing wallet [{wallet}]: \n"

        response += "\n\n\nWallets updated"
    except Exception as e:
        response += "\nException occurred: " + str(e)

    response = "<pre>\n\n" + response + "\n\n</pre>\n"

    return https_fn.Response(response)



@https_fn.on_request()
def update_wallets_balance(request: https_fn.Request) -> https_fn.Response:
    response = ""

    try:
        firestore_client: google.cloud.firestore.Client = firestore.client()
        start_timestamp = time.time()

        wallets = load_all_wallets_from_visitors_sessions()
        response += "\nAll wallets: " + str(wallets) + "\n"

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

            firestore_client \
                .collection("wallets") \
                .document(wallet) \
                .collection("balance_history") \
                .document(str(start_timestamp)) \
                .set(wallet_net_worth_in_usd_response, merge=True)

            firestore_client \
                .collection("wallets") \
                .document(wallet) \
                .set({"balance_updated_at": start_timestamp}, merge=True)

            response += f"\n\n\nNet-worth fetch result for wallet [{wallet}]: \n" + str(wallet_net_worth_in_usd_response)
            response += f"\n\n\n<<< END processing wallet [{wallet}]: \n"

        response += "\n\n\nWallets updated"
    except Exception as e:
        response += "\nException occurred: " + str(e)

    response = "<pre>\n\n" + response + "\n\n</pre>\n"

    return https_fn.Response(response)