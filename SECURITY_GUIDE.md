# Zanny Collection — Security Infrastructure Guide

This document provides a detailed overview of the security measures, configuration guidelines, and best practices implemented for the **Zanny Collection Mobile App** and **Website/API Backend**. 

Our security architecture utilizes a hybrid approach: **Cloudflare Edge Infrastructure** manages network-level threats, while **Client/Worker Application Logic** enforces frontend and application-layer security.

---

## 🛡️ 1. IP Blocking

IP Blocking is handled at the Cloudflare Edge network layer to ensure malicious actors are blocked before reaching our database or worker execution threads. This minimizes database load and worker execution costs.

*   **How it is handled**:
    *   **Cloudflare WAF (Web Application Firewall) / IP Access Rules**: Administrators can block specific IP addresses, CIDR blocks (IP ranges), or entire countries/ASNs directly via the Cloudflare Dashboard.
    *   **Implementation details**:
        1. Log in to the [Cloudflare Dashboard](https://dash.cloudflare.com/).
        2. Navigate to **Security > WAF > Tools**.
        3. Under **IP Access Rules**, you can add rules:
           * **Value**: Enter the IP address (e.g., `192.0.2.1` or `198.51.100.0/24`).
           * **Action**: Choose `Block`, `Challenge (Managed)`, or `JS Challenge`.
           * **Zone**: Apply to all website zones or specific ones.

---

## 🧱 2. Firewall Rules

Custom firewall rules inspect incoming HTTP requests and block, challenge, or allow them based on specific parameters (headers, paths, threat levels).

*   **How it is handled**:
    *   **Cloudflare WAF Custom Rules**: Leverages Cloudflare’s expression builder to identify and filter out malicious traffic.
    *   **Recommended Rules**:
        1. **Admin Path Protection**: Block or challenge access to admin or sensitive endpoints unless the request comes from a trusted IP address.
        2. **Threat Score Blocking**: Block requests with a high Cloudflare Threat Score (e.g., `cf.threat_score ge 10`).
        3. **Known Malicious User Agents**: Block scrapers or automated tools targeting `/api/products` or `/api/auth`.
    *   **Implementation details**:
        * Define these under **Security > WAF > Custom Rules** in Cloudflare. 
        * Example rule expression: `(http.request.uri.path contains "/api/admin/" and not ip.src in {your_trusted_ips})` -> **Block**.

---

## 🌊 3. DDoS Protection

DDoS (Distributed Denial of Service) protection mitigates bulk traffic spikes designed to take down the API database or the frontend web app.

*   **How it is handled**:
    *   **Cloudflare Advanced DDoS Protection**: Enabled natively. Cloudflare operates an unmetered, always-on DDoS mitigation system at Layers 3, 4, and 7.
    *   **Edge Mitigation**: Attack traffic is automatically recognized and neutralized at Cloudflare’s global Edge nodes (closest to the source) before it reaches the backend worker or D1 database.
    *   **HTTP DDoS Managed Rules**: Cloudflare has built-in rulesets to detect common attack patterns (e.g., HTTP flood attacks). Under **Security > DDoS**, ensure the protection level is set to `High` or `Medium (Default)`.

---

## ⚡ 4. Rate Limiting

Rate Limiting prevents brute-force attacks on login endpoints and stops abusive scraping of products.

*   **How it is handled**:
    *   **Cloudflare Rate Limiting Rules**: Configured at the Edge to count requests from individual IP addresses and temporarily block them if they exceed safety thresholds.
    *   **Recommended Thresholds**:
        1. **Authentication Endpoints (`/api/auth/signin`, `/api/auth/signup`, `/api/auth/forgot-password`)**: Limit to 10 requests per minute per IP. Action: `Block` or `Managed Challenge` for 1 hour.
        2. **General API Endpoints (`/api/*`)**: Limit to 100 requests per minute per IP. Action: `Block` or `Rate Limit` for 10 minutes.
    *   **Implementation details**:
        * In the Cloudflare Dashboard, go to **Security > WAF > Rate limiting rules** and create rules targeting paths starting with `/api/auth/`.

---

## 🔒 5. Frontend & Application Security

Frontend and client-side security is distributed between our Flutter mobile app, website frontend, and the API worker headers.

### A. Mobile App Security (Flutter Client)
*   **Encrypted Storage (`FlutterSecureStorage`)**: User login tokens are encrypted and saved inside the device's secure hardware vault (Key Store for Android, Keychain for iOS) rather than plain files. This prevents key theft on rooted or compromised devices.
*   **SSL Pinning**: The app hardcodes verified SSL root certificates (Google, Let's Encrypt, DigiCert). The app rejects connection attempts if the server certificate doesn't match, stopping Man-in-the-Middle (MitM) sniffing on public Wi-Fi networks.
*   **Code Obfuscation**: The compiled APK/IPA is obfuscated (`--obfuscate --split-debug-info`), turning class names and routes into unreadable text (e.g., `a`, `b`). This makes reverse engineering the application extremely difficult.

### B. API Worker Security & CORS
*   **CORS Whitelisting**: The Cloudflare Worker API ([index.js](file:///c:/Users/Administrator/Desktop/zanny%20collection%20application/cloudflare-worker/src/index.js)) restricts browser requests. It reads the incoming `Origin` header and checks it against a whitelist:
    ```javascript
    const allowedOrigins = [
      'https://zannycollection.com',
      'https://www.zannycollection.com',
      'https://zanny-collection.pages.dev'
    ];
    ```
    If the requesting website origin is not in this list (or not localhost during development), the worker returns a fallback configuration to block unauthorized third-party site requests.
*   **Secure Environment Variables**: Sensitive keys (such as `JWT_SECRET`) are not stored in code. They are bound securely to the worker environment via Wrangler Secrets (`wrangler secret put JWT_SECRET`).
