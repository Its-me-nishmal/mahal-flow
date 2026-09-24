#!/usr/bin/env python3
"""Seed committee admin phones for MahalFlow phone-based login.

A phone found in the `admins` collection resolves to an admin session at login.
Run once:  python3 scripts/seed_admins.py
"""
from datetime import datetime, timezone
from pymongo import MongoClient

db = MongoClient("mongodb://localhost:27017").mahalflow
now = datetime.now(timezone.utc)

admins = [
    {"_id": "ADM_MH001_1", "mahal_id": "MH_001_CALICUT",
     "name": "Nishmal (Committee)", "phone": "+917994107442", "created_at": now},
    {"_id": "ADM_MH001_2", "mahal_id": "MH_001_CALICUT",
     "name": "Demo Admin", "phone": "+919847123456", "created_at": now},
]
for a in admins:
    db.admins.update_one({"_id": a["_id"]}, {"$set": a}, upsert=True)

print("Seeded admins:")
for a in db.admins.find({}, {"phone": 1, "name": 1, "mahal_id": 1}):
    print(" ", a)
