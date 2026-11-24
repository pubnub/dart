# Crypto guide

`lib/src/crypto/` implements message and file encryption. `CryptoModule` encrypts with one default cryptor and decrypts with whichever registered cryptor the payload header names. The contracts `ICryptoModule`, `ICryptor`, `EncryptedData`, and `CryptoException` live in `../core/crypto/crypto.dart`. Consumers import `package:pubnub/crypto.dart`.

## Key files

| File | Contents |
| --- | --- |
| `crypto.dart` | `CryptoModule`: `encrypt` / `decrypt`, `*WithKey`, and `*FileData`. Factories `CryptoModule.aesCbcCryptoModule(cipherKey)` (recommended) and `CryptoModule.legacyCryptoModule(cipherKey)` (`@Deprecated`). |
| `cryptorHeader.dart` | `CryptorHeader`: the `PNED` sentinel, version, 4-byte cryptor identifier, and metadata length. |
| `aesCbcCryptor.dart` | `AesCbcCryptor`, identifier `ACRH`. |
| `legacyCryptor.dart` | `LegacyCryptor` (identifier `''`, `@Deprecated`) and `LegacyCryptoModule`, the default when no crypto is configured. |
| `aes_gcm_cryptor.dart` | `AesGcmCryptor`, identifier `ACGM`. **Decrypt-only**, `@nodoc`, and not exported. |
| `cryptoConfiguration.dart` | `CryptoConfiguration`. `useRandomInitializationVector` is `@Deprecated`. |
| `encryption_mode.dart` | `EncryptionMode` and its extension. |

## How it fits

- `PubNub(...)` (`../default.dart`) uses `CryptoModule.legacyCryptoModule(cipherKey)` when the default keyset has a `cipherKey`, otherwise `LegacyCryptoModule()`. A `crypto:` argument overrides both.
- Callers: publish encrypts in `../dx/publish/publish.dart`. The subscribe loop decrypts (`../subscribe/subscribe_loop/subscribe_loop.dart`). Files encrypt and decrypt file data in `../dx/files/`. History decrypts fetched messages.
- Header format: `CryptoModule.encrypt` writes `PNED` + version + identifier + metadata, followed by the ciphertext. Data without a header is legacy data and goes to the cryptor with identifier `''`.
- Both factories register all three cryptors for decryption, so a client decrypts data written by any of them. `LegacyCryptoModule` tries `AesGcmCryptor.tryDecrypt` first, then legacy decryption.

## Invariants

- Never document or expose AES-GCM **encryption**. `AesGcmCryptor.encrypt` throws `CryptoException`. Its only purpose is to read `ACGM` payloads produced by other PubNub SDKs.
- Keep error messages opaque, for example `'decryption error'`. Distinguishable failure messages create a padding or authentication oracle. Log the underlying cause instead.
- Throw `CryptoException` for every crypto failure, including a malformed `PNED` header. Never let `RangeError` or `FormatException` escape.
- Cryptor identifiers are a cross-SDK wire format. Do not change existing ones; a new cryptor needs a new 4-character identifier agreed across SDKs.
- Do not rename the camelCase files here; `lib/crypto.dart` and tests import them by path.

## Deprecations in force

`CryptoModule.legacyCryptoModule`, `LegacyCryptor`, `Keyset(cipherKey:)`, and `CryptoConfiguration.useRandomInitializationVector`. Inside the package, mark their uses with `// ignore: deprecated_member_use_from_same_package`. New code and snippets use `CryptoModule.aesCbcCryptoModule`.

## Adding a cryptor

1. Implement `ICryptor` with a fixed `identifier` and `EncryptedData` metadata.
2. Register it in the decrypt list of both `CryptoModule` factories, and make it the default cryptor only in a new factory.
3. Export it from `lib/crypto.dart` only once encryption is supported and announced.
4. Test with known-answer vectors from the cross-SDK specification, in the table style of `test/unit/crypto/aes_gcm_cryptor_test.dart` with a `reason:` on each `expect`. Also add round-trip, wrong-key, truncated, and malformed-header cases.
