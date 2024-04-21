import importlib
import subprocess
import time
import sys
from datetime import datetime



def import_or_install(module_name, version=None):
    try:
        importlib.import_module(module_name)
        print(f"Module '{module_name}' is already installed.")
    except ImportError:
        print(f"Module '{module_name}' not found. Trying to install...")
        try:
            module_name = module_name if version is None else f"{module_name}=={version}"
            subprocess.check_call(["pip", "install", module_name])
            print(f"Module '{module_name}' installed successfully.")
        except Exception as e:
            print(f"Couldn't install module '{module_name}'. Error: '{e}'")



print(sys.version)
import_or_install('firebase_admin', '4.5.1')
import_or_install('google.cloud.firestore')
import_or_install('moralis')



# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore, credentials
import google.cloud.firestore
from moralis import evm_api



MORALIS_API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJub25jZSI6IjI2OWIwMzI1LWViMjctNDA5Ni1iY2VjLTYxMGQ4YmJmYjRiYyIsIm9yZ0lkIjoiMzgyNDQyIiwidXNlcklkIjoiMzkyOTY0IiwidHlwZUlkIjoiMDU5MWQ5NzItZGU3OC00ZjNjLTllMTYtNzU4OGQ1NTJjMjg2IiwidHlwZSI6IlBST0pFQ1QiLCJpYXQiOjE3MTAyNDkzNjcsImV4cCI6NDg2NjAwOTM2N30.u0OgFrKWer9nuFq2cimZZfv4CNgeqeYlZxCEpWDHrSM"



credentials = credentials.Certificate("/Users/serg_mykhailov/Downloads/myriads-39550-firebase-adminsdk-9ente-b54771914a.json")
initialize_app(credentials)



class WalletUpdadeInfo:
    def __init__(self, wallet_address, transactions_update_timestamp, balance_update_timestamp):
        self.wallet_address = wallet_address
        self.transactions_update_timestamp = transactions_update_timestamp
        self.balance_update_timestamp = balance_update_timestamp



    def __repr__(self):
        return f"WalletUpdateInfo(wallet_address={self.wallet_address}, transactions_update_timestamp={self.transactions_update_timestamp}, balance_update_timestamp={self.balance_update_timestamp})"



def load_all_wallets_from_visitors_sessions() -> set[str]:
    firestore_client: google.cloud.firestore.Client = firestore.client()

    wallets = set()

    domains = firestore_client.collection("domains").stream()

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



def update_transactions_of_wallets(wallets) -> str:
    try:
        firestore_client: google.cloud.firestore.Client = firestore.client()
        requests_count = 0

        for wallet in wallets:
            print(f">>> BEGIN processing wallet [{wallet}]:")

            cursor = None

            while True:
                params = {
                    "chain": "eth",
                    "order": "DESC",
                    "address": wallet
                }

                if cursor is not None and cursor.strip():
                    params["cursor"] = cursor

                wallet_history_response = evm_api.wallets.get_wallet_history(
                    api_key=MORALIS_API_KEY,
                    params=params,
                )

                requests_count += 1

                cursor = wallet_history_response.get("cursor")

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
                    current_timestamp = time.time()
                    firestore_client \
                        .collection("wallets") \
                        .document(wallet) \
                        .set({"transactions_updated_at": current_timestamp}, merge=True)
                    break

            print(f"<<< END processing wallet [{wallet}]:")
    except Exception as e:
        print(f"Exception occurred: " + str(e))
    
    
    
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



def update_wallets_transactions():
    try:
        wallets = load_all_wallets_from_visitors_sessions()
        print(f"All wallets: " + str(wallets))

        existing_wallets_updates = load_all_existing_wallets_updates()
        fresh_wallets = find_fresh_wallets(wallets, existing_wallets_updates)

        print(f"Fresh wallets: " + str(fresh_wallets))
        update_transactions_of_wallets(fresh_wallets)

        existing_wallets_sorted = sorted(
            existing_wallets_updates,
            key = lambda element: element.transactions_update_timestamp if element.transactions_update_timestamp is not None else float('-inf')
        )
        print(f"Wallets sorted by transactions update time: " + str(existing_wallets_sorted))

        existing_wallets_addresses_sorted = [element.wallet_address for element in existing_wallets_sorted]
        print(f"Wallets addresses sorted by transactions update time: " + str(existing_wallets_addresses_sorted))

        update_transactions_of_wallets(existing_wallets_addresses_sorted)
    except Exception as e:
        print(f"Exception occurred: " + str(e))



def update_balance_of_wallets(wallets):
    try:
        firestore_client: google.cloud.firestore.Client = firestore.client()

        for wallet in wallets:
            print(f">>> BEGIN processing wallet [{wallet}]:")

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
            
            print(f"<<< END processing wallet [{wallet}]:")
    except Exception as e:
        print("Exception occurred: " + str(e))



def update_wallets_balance(): 
    try:
        print(f">>> BEGIN updating wallets balances...")

        wallets = load_all_wallets_from_visitors_sessions()
        existing_wallets_updates = load_all_existing_wallets_updates()
        fresh_wallets = find_fresh_wallets(wallets, existing_wallets_updates)

        update_balance_of_wallets(fresh_wallets)

        existing_wallets_sorted = sorted(
            existing_wallets_updates,
            key = lambda element: element.balance_update_timestamp if element.balance_update_timestamp is not None else float('-inf')
        )
        
        existing_wallets_addresses_sorted = [element.wallet_address for element in existing_wallets_sorted]
        update_balance_of_wallets(existing_wallets_addresses_sorted)

        print(f"<<< END updating wallets balances")
    except Exception as e:
        print("Exception occurred: " + str(e))



start_time = datetime.now()
update_wallets_transactions()
completion_time = datetime.now()

formatted_start_time = start_time.strftime("%Y-%m-%d %H:%M:%S")
formatted_completion_time = completion_time.strftime("%Y-%m-%d %H:%M:%S")
print(f"Transactions update started at: {formatted_start_time}, completed at: {formatted_completion_time}")

start_time = datetime.now()
update_wallets_balance()
completion_time = datetime.now()

formatted_start_time = start_time.strftime("%Y-%m-%d %H:%M:%S")
formatted_completion_time = completion_time.strftime("%Y-%m-%d %H:%M:%S")
print(f"Balance update started at: {formatted_start_time}, completed at: {formatted_completion_time}")