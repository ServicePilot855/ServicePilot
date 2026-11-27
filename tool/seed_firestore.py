#!/usr/bin/env python3
"""
Idempotent Cloud Firestore Seeder for ServicePilot.
Seeds service categories and verified Phnom Penh providers into servicepilot-855.
Uses project admin credentials from Firebase CLI configstore.
"""

import json
import os
import sys
import urllib.request
import urllib.error

PROJECT_ID = "servicepilot-855"
DATABASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

def get_access_token():
    config_path = os.path.expanduser("~/.config/configstore/firebase-tools.json")
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"Firebase credentials not found at {config_path}")
    with open(config_path, "r") as f:
        data = json.load(f)
    token = data.get("tokens", {}).get("access_token")
    if not token:
        raise ValueError("No access token found in firebase-tools.json")
    return token

def to_firestore_value(val):
    if val is None:
        return {"nullValue": None}
    if isinstance(val, bool):
        return {"booleanValue": val}
    if isinstance(val, int):
        return {"integerValue": str(val)}
    if isinstance(val, float):
        return {"doubleValue": val}
    if isinstance(val, str):
        return {"stringValue": val}
    if isinstance(val, list):
        return {"arrayValue": {"values": [to_firestore_value(v) for v in val]}}
    if isinstance(val, dict):
        return {"mapValue": {"fields": {k: to_firestore_value(v) for k, v in val.items()}}}
    return {"stringValue": str(val)}

def upsert_document(collection: str, doc_id: str, data: dict, token: str):
    fields = {k: to_firestore_value(v) for k, v in data.items()}
    body = json.dumps({"fields": fields}).encode("utf-8")
    
    # PATCH with document path creates or overwrites with full field merge
    url = f"{DATABASE_URL}/{collection}/{doc_id}"
    req = urllib.request.Request(
        url,
        data=body,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="PATCH",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            print(f"  [OK] {collection}/{doc_id} (status: {resp.status})")
    except urllib.error.HTTPError as e:
        print(f"  [ERROR] {collection}/{doc_id}: HTTP {e.code} - {e.read().decode()}")

CATEGORIES = [
    {
        "id": "cat-ac",
        "name": "Air Conditioner Repair & Care",
        "description": "Deep chemical wash, refrigerant gas refill, compressor inspection, and leak fixes.",
        "iconName": "ac_unit",
        "providerCount": 12,
        "isActive": True,
        "popularServices": ["Deep Cleaning", "Gas Top-up", "Water Leak Fix", "Installation"],
    },
    {
        "id": "cat-plumbing",
        "name": "Plumbing & Drainage",
        "description": "Pipe leak repairs, bathroom fixtures, pump installation, and drain unblocking.",
        "iconName": "plumbing",
        "providerCount": 9,
        "isActive": True,
        "popularServices": ["Leak Detection", "Pipe Replacement", "Toilet Repair", "Water Heater"],
    },
    {
        "id": "cat-electrical",
        "name": "Electrical & Wiring",
        "description": "Short circuit diagnosis, breaker replacement, smart switch setup, and fixture installation.",
        "iconName": "bolt",
        "providerCount": 8,
        "isActive": True,
        "popularServices": ["Short Circuit Fix", "Ceiling Fan Install", "Lighting", "Breaker Box"],
    },
    {
        "id": "cat-appliance",
        "name": "Appliance Repair",
        "description": "Diagnostics and repair for refrigerators, washing machines, microwaves, and ovens.",
        "iconName": "appliance",
        "providerCount": 7,
        "isActive": True,
        "popularServices": ["Washing Machine", "Refrigerator", "Microwave", "Induction Cooker"],
    },
    {
        "id": "cat-cleaning",
        "name": "Home & Room Cleaning",
        "description": "Comprehensive deep cleaning, move-in/move-out sanitize, and upholstery vacuuming.",
        "iconName": "cleaning",
        "providerCount": 15,
        "isActive": True,
        "popularServices": ["Deep Clean", "Sofa Washing", "Move-in Sanitization", "Post-renovation"],
    },
    {
        "id": "cat-locksmith",
        "name": "Locksmith & Security",
        "description": "Door lock replacement, emergency lockout assistance, and digital lock setup.",
        "iconName": "tools",
        "providerCount": 0,
        "isActive": True,
        "popularServices": ["Emergency Lockout", "Key Duplication", "Smart Lock"],
    },
]

PROVIDERS = [
    {
        "id": "prov-virak-ac",
        "name": "Virak Chan",
        "email": "technician@test.com",
        "phone": "+85587654321",
        "type": "independent",
        "status": "active",
        "serviceArea": "Toul Kork, Phnom Penh",
        "categoryIds": ["cat-ac", "cat-electrical"],
        "rating": 4.9,
        "reviewCount": 42,
        "completedJobs": 118,
        "hourlyRate": 15.0,
        "bio": "Certified HVAC technician with 7+ years of experience in Daikin, Panasonic, and LG inverter systems. Expert in chemical cleaning and leak diagnosis.",
        "isAvailable": True,
        "createdAt": "2025-01-10T00:00:00Z",
    },
    {
        "id": "prov-fixco-company",
        "name": "Sophea Lim",
        "businessName": "Phnom Penh Fix Co.",
        "email": "company@test.com",
        "phone": "+85511223344",
        "type": "company",
        "status": "active",
        "serviceArea": "Chamkarmon, Sen Sok, Phnom Penh",
        "categoryIds": ["cat-plumbing", "cat-appliance", "cat-ac"],
        "rating": 4.8,
        "reviewCount": 86,
        "completedJobs": 320,
        "hourlyRate": 20.0,
        "bio": "Licensed maintenance company with 12 dispatched technicians. 24/7 emergency response for plumbing failures, water heaters, and major appliances.",
        "isAvailable": True,
        "createdAt": "2024-11-01T00:00:00Z",
    },
    {
        "id": "prov-borey-electric",
        "name": "Borey Nhem",
        "email": "tech@company.com",
        "phone": "+85599887766",
        "type": "independent",
        "status": "active",
        "serviceArea": "Daun Penh, Phnom Penh",
        "categoryIds": ["cat-electrical", "cat-appliance"],
        "rating": 4.7,
        "reviewCount": 19,
        "completedJobs": 54,
        "hourlyRate": 12.0,
        "bio": "Master residential electrician. Specializing in circuit breaker panel upgrades, short-circuit troubleshooting, and smart home lighting setup.",
        "isAvailable": True,
        "createdAt": "2025-03-05T00:00:00Z",
    },
    {
        "id": "prov-cleanpro-cambodia",
        "name": "CleanPro Cambodia",
        "businessName": "CleanPro Cambodia Co.",
        "email": "cleanpro@servicepilot.local",
        "phone": "+85523999888",
        "type": "company",
        "status": "active",
        "serviceArea": "All Phnom Penh",
        "categoryIds": ["cat-cleaning", "cat-ac"],
        "rating": 4.9,
        "reviewCount": 104,
        "completedJobs": 410,
        "hourlyRate": 18.0,
        "bio": "Top-rated home deep cleaning and sanitization team. Eco-friendly hospital-grade disinfectants, upholstery shampooing, and move-in/out prep.",
        "isAvailable": True,
        "createdAt": "2024-08-15T00:00:00Z",
    },
    {
        "id": "prov-dara-plumbing",
        "name": "Sophea Lim Services",
        "email": "sophea.plumb@servicepilot.local",
        "phone": "+85512778899",
        "type": "independent",
        "status": "active",
        "serviceArea": "Boeung Keng Kang (BKK), Phnom Penh",
        "categoryIds": ["cat-plumbing"],
        "rating": 4.8,
        "reviewCount": 31,
        "completedJobs": 89,
        "hourlyRate": 14.0,
        "bio": "Prompt, reliable plumbing repairs. Expert in high-pressure water pump installations, bathroom fixture replacements, and drain pipe unblocking.",
        "isAvailable": True,
        "createdAt": "2025-02-20T00:00:00Z",
    },
]

OFFERINGS = [
    {
        "id": "offering-sophea-sonar-leak",
        "providerId": "prov-dara-plumbing",
        "providerName": "Sophea Lim Services",
        "providerType": "independent",
        "categoryId": "cat-plumbing",
        "categoryName": "Plumbing & Drainage",
        "title": "Underground Pipe Leak Sonar Inspection",
        "description": "Advanced ultrasonic acoustic sonar leak detection for concealed breaks in water mains and under-slab plumbing.",
        "pricingMode": "quoteRequired",
        "price": None,
        "unit": "job",
        "isActive": True,
        "createdAt": "2025-03-01T00:00:00Z",
    },
    {
        "id": "offering-sophea-drain-unblock",
        "providerId": "prov-dara-plumbing",
        "providerName": "Sophea Lim Services",
        "providerType": "independent",
        "categoryId": "cat-plumbing",
        "categoryName": "Plumbing & Drainage",
        "title": "High-Torque Drain Snake Unblocking",
        "description": "Mechanical drain snaking for clearing kitchen, bathroom, and main line blockages.",
        "pricingMode": "fixed",
        "price": 25.0,
        "unit": "job",
        "isActive": True,
        "createdAt": "2025-03-01T00:00:00Z",
    },
    {
        "id": "offering-virak-ac-quote",
        "providerId": "prov-virak-ac",
        "providerName": "Virak Chan",
        "providerType": "independent",
        "categoryId": "cat-ac",
        "categoryName": "Air Conditioner Repair & Care",
        "title": "Multi-Split VRV Diagnostic & Custom Piping",
        "description": "Comprehensive multi-split inverter diagnostics and custom refrigerant pipe sizing. Requires on-site quote assessment.",
        "pricingMode": "quoteRequired",
        "price": None,
        "unit": "job",
        "isActive": True,
        "createdAt": "2025-03-01T00:00:00Z",
    },
    {
        "id": "offering-fixco-commercial-quote",
        "providerId": "prov-fixco-company",
        "providerName": "Phnom Penh Fix Co.",
        "providerType": "company",
        "categoryId": "cat-plumbing",
        "categoryName": "Plumbing & Drainage",
        "title": "Commercial Building Sewer System Overhaul",
        "description": "Heavy industrial sewer relining, grease trap rebuilds, and pump station maintenance. Custom quote required upon blueprint inspection.",
        "pricingMode": "quoteRequired",
        "price": None,
        "unit": "job",
        "isActive": True,
        "createdAt": "2025-03-01T00:00:00Z",
    },
]

def main():
    print(f"Connecting to Firestore for project: {PROJECT_ID}...")
    token = get_access_token()
    
    print("\n--- Seeding /categories ---")
    for cat in CATEGORIES:
        upsert_document("categories", cat["id"], cat, token)
        
    print("\n--- Seeding /providers ---")
    for prov in PROVIDERS:
        upsert_document("providers", prov["id"], prov, token)

    print("\n--- Seeding /offerings ---")
    for off in OFFERINGS:
        upsert_document("offerings", off["id"], off, token)

    print("\nFirestore cloud seeding successfully completed!")

if __name__ == "__main__":
    main()
