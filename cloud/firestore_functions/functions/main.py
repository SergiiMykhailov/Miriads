from firebase_functions import firestore_fn, https_fn

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore
import google.cloud.firestore
import time


initialize_app()


@https_fn.on_request()
def record_entry(request: https_fn.Request) -> https_fn.Response:
    """Take the text parameter passed to this HTTP endpoint and insert it into
    a new document in the messages collection."""
    # Grab the text parameter.
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