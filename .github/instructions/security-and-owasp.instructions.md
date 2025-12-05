# Secure Coding and OWASP Guidelines

## Instructions

### 1. A01: Broken Access Control & A10: Server-Side Request Forgery (SSRF)
- Enforce Principle of Least Privilege.
- Deny by Default.
- Validate all incoming URLs for SSRF; use allow-lists.
- Prevent path traversal by sanitizing file paths.

### 2. A02: Cryptographic Failures
- Use strong, modern algorithms (Argon2/bcrypt for passwords).
- Protect data in transit (HTTPS) and at rest (AES-256 where appropriate).
- Never hardcode secrets; read from env or secret managers.

### 3. A03: Injection
- Use parameterized queries; never build queries with string concatenation.
- Sanitize command-line inputs; avoid shell injection.
- Prevent XSS: use context-aware encoding and avoid innerHTML.

### 4. A05: Security Misconfiguration & A06: Vulnerable Components
- Secure-by-default configuration, set security headers, and keep dependencies up to date.

### 5. A07: Identification & Authentication Failures
- Secure session management, rate limiting, and account lockout strategies.

### 6. A08: Software and Data Integrity Failures
- Avoid insecure deserialization and prefer safer formats like JSON.

## General Guidelines
- Be explicit about what you are protecting against when suggesting code.
- Educate during code reviews: provide corrected code and explanations.

---
applyTo: '*'
description: "Comprehensive secure coding instructions for all languages and frameworks, based on OWASP Top 10 and industry best practices."
