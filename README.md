# 🔐 RC5 Cryptography on AVR (ATmega328P)

![License](https://img.shields.io/badge/license-MIT-blue.svg) 
![Status](https://img.shields.io/badge/status-completed-brightgreen.svg) 
![Architecture](https://img.shields.io/badge/architecture-AVR%20Assembly-orange.svg) 
![Platform](https://img.shields.io/badge/platform-ATmega328P-yellow.svg) 

![intro](https://github.com/user-attachments/assets/e1c8882d-e138-4898-b6f6-f8209d3cd618)

> A **high-performance, educational implementation** of the **RC5 symmetric-key encryption algorithm** written entirely in **AVR Assembly**, designed for the **ATmega328P microcontroller**.  
> Featuring:
> - Full **key expansion**
> - Clean **encryption & decryption**
> - Handcrafted **macros**
> - No libraries — just pure register magic ✨

---

## 📋 Outline

- [📦 Features](#-features)
- [🧩 Core Components Explained](#-core-components-explained)
  - [🔄 RC5 Encryption Workflow](#-rc5-encryption-workflow)
  - [👾 Algorithm Flowchart](#-algorithm-flowchart)
    - [🧮 RC5 Key Expansion Overview](#-rc5-key-expansion-overview)
      - [📦 Memory Layout](#-memory-layout)
      - [🔮 Magic Constants & Predefined Key](#-magic-constants--predefined-key)
      - [🧠 S-array Initialization](#-s-array-initialization)
      - [📋 L-array Initialization](#-l-array-initialization)
      - [🔄 Mixing Step](#-mixing-step)
      - [⚙️ Code Implementation Highlights 1](#-code-implementation-highlights-1)
        - [🧠 S-array Initialization- code](#-s-array-initialization-code)
        - [📋 L-array Initialization](#-l-array-initialization)
        - [🔄 Mixing Step](#-mixing-step)
- [🔐 RC5 Encryption Process](#-rc5-encryption-process)
- [🔓 RC5 Decryption Process](#-rc5-decryption-process)
- [🧪 Sample Execution Flow](#-sample-execution-flow)
- [🔐 Security Considerations](#-security-considerations)
- [📘 Use Cases](#-use-cases)
- [🛠 Hardware Requirements](#-hardware-requirements)
- [🛠️ Toolchain & Simulation](#️-toolchain--simulation)
- [📂 Project Structure](#-project-structure)
- [🚧 Limitations](#-limitations)
- [🧠 Future Improvements](#-future-improvements)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)
- [📚 References](#-references)
- [💬 Author](#-author)

---

## 📦 Features

- 🧮 Pure **AVR Assembly** – no libraries or frameworks used
- 🎯 Optimized for **ATmega328P**
- 🧱 Modular structure using **macros** for cleaner code
- 🔄 Full implementation of **RC5 key expansion**, **encryption**, and **decryption**
- 🛡️ Secure memory handling with `secure_clear`
- 📊 Diagrams included for:
  - 🔁 **Rotation logic**
  - 🔢 **S-array construction**
  - 🔄 **Encryption workflow**

---

## 🧩 Core Components Explained

### 🔄 RC5 Encryption Workflow

 <img width="1440" alt="Screenshot 2025-06-06 at 9 23 40 PM" src="https://github.com/user-attachments/assets/c2cbd56e-1681-4d57-8cc9-f6d4c59ff817" />

### 👾 Algorithm Flowchart


<img width="1436" alt="Screenshot 2025-06-06 at 9 39 10 PM" src="https://github.com/user-attachments/assets/e6be0e6d-9e7c-4969-b8ab-3d95a970275a" />





## 🧮 RC5 Key Expansion Overview

<img width="1439" alt="Screenshot 2025-06-06 at 9 41 04 PM" src="https://github.com/user-attachments/assets/45821fa3-2ddb-40e0-bcc6-03ba0a3b7596" />


RC5 uses a **key-dependent S array** generated through a deterministic process involving:
- Two arrays: **S-array** (expanded key table), **L-array** (key split into words)
- Three stages:
  1. **Initialization of S-array**
  2. **Initialization of L-array**
  3. **Mixing step** that combines both arrays
 
  <img width="1439" alt="Screenshot 2025-06-06 at 9 41 45 PM" src="https://github.com/user-attachments/assets/99a86995-dc8f-4f25-9d3a-51e3459275af" />


This ensures strong cryptographic entropy from even small keys.

---

## 📦 Memory Layout

To avoid overlap and ensure clarity, memory is manually assigned as follows:

| Section      | Start Address | Size     | Description                     |
|--------------|---------------|----------|---------------------------------|
| `plaintext`  | 0x0060        | 4 bytes  | Input plaintext (A, B)          |
| `ciphertext` | 0x0064        | 4 bytes  | Encrypted output                |
| `key`        | 0x0068        | 12 bytes | Secret key                      |
| `L`          | 0x0074        | 6 words  | Split key in 16-bit words       |
| `S`          | 0x0080        | 18 words | Expanded key table              |

All values are accessed directly via registers or indirect addressing.


---

## 🔮 Magic Constants & Predefined Key

### 🪄 Magic Constants
Used to initialize the **S-array** before mixing:
- `Pw = 0xB7E1`
- `Qw = 0x9E37`

These values are derived from mathematical constants and provide good diffusion.

<img width="1439" alt="Screenshot 2025-06-06 at 9 42 50 PM" src="https://github.com/user-attachments/assets/a3c57684-9a24-4701-a220-2f10de4833d7" />




### 🔒 Predefined Secret Key

Example key used in this implementation:
```asm
key:
    .byte 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB
    .byte 0xCD, 0xEF, 0xFE, 0xDC, 0xBA, 0x98
```

This is a **12-byte (96-bit)** key, which maps to `c = 6` 16-bit words.



## 🧠 S-array Initialization

The **S-array** starts with repeated additions of the constant `Pw`.

### 🧩 Process:
1. Initialize `S[0] = Pw`
2. For each subsequent index:
   ```text
   S[i] = S[i-1] + Qw
   ```

### 🖼 Diagram:

![ScreenRecorderProject7-ezgif com-optimize](https://github.com/user-attachments/assets/99280db0-e545-4753-af8d-76967300a358)


Each entry contributes to the overall entropy of the cipher.

---

## 📋 L-array Initialization

The **L-array** is built by splitting the user-provided key into 16-bit words.

### 🧩 Process:
1. Load key bytes from memory
2. Combine two bytes at a time:
   ```text
   L[i] = key[2*i] | (key[2*i+1] << 8)
   ```

![ScreenRecorderProject8_1-ezgif com-optimize](https://github.com/user-attachments/assets/e5c25afc-f293-46e0-8975-c348aa4e7aca)


This results in `c = b / 2` 16-bit words.

---

## 🔄 Mixing Step

This stage mixes the **S-array** and **L-array** together using a series of operations:
- Addition
- XOR
- Rotation

### 🧩 Process:
1. Initialize counters `A = 0`, `B = 0`, `i = 0`, `j = 0`
2. Loop over `n = 3 * max(t, c)` iterations:
   ```text
   A = (A + S[i] + L[j]) <<< 3
   S[i] = A
   B = (B + S[j] + L[i]) <<< (A + B)
   S[j] = B
   i = (i + 1) % t
   j = (j + 1) % c
   ```



This creates a highly entropic and secure expanded key table.

---

## ⚙️ Code Implementation Highlights 1
### 🧠 S-array Initialization code



https://github.com/user-attachments/assets/0c98b78e-efb9-4a48-ba04-b424e7e9f9f0



---

## 🔐 RC5 Encryption Process

RC5 encryption applies a series of rounds to transform plaintext into ciphertext using the S-array.

### 🧩 Process:
1. Load initial values:
   ```text
   A = plaintext[0], B = plaintext[1]
   ```
2. Add initial key:
   ```text
   A = A + S[0], B = B + S[1]
   ```
3. Perform `r` rounds:
   ```text
   A = ((A ^ B) <<< B) + S[2*i]
   B = ((B ^ A) <<< A) + S[2*i+1]
   ```

### 🖼 Diagram:

```mermaid
graph LR
    A[Plaintext Input] --> B((Register A & B))
    B --> C((Add S[0], S[1]))
    C --> D{{Round 1}}
    D --> E{{Round 2}}
    E --> F{{...}}
    F --> G{{Round r}}
    G --> H[Ciphertext Output]
```

---

## 🔓 RC5 Decryption Process

Decryption reverses the encryption steps using the same S-array in reverse order.

### 🧩 Process:
1. Load encrypted values:
   ```text
   A = ciphertext[0], B = ciphertext[1]
   ```
2. Subtract final key:
   ```text
   A = A - S[2*r+1], B = B - S[2*r]
   ```
3. Reverse `r` rounds:
   ```text
   B = ((B - S[2*i+1]) >>> A) ^ A
   A = ((A - S[2*i]) >>> B) ^ B
   ```

### 🖼 Diagram:

```mermaid
graph RL
    H[Ciphertext Input] --> G{{Round r}}
    G --> F{{Round r-1}}
    F --> E{{...}}
    E --> D{{Round 1}}
    D --> C((Subtract S[0], S[1]))
    C --> A[Plaintext Output]
```

---

## ⚙️ Code Implementation Highlights

### 🧰 Why Use Macros?

Macros help reduce repetitive tasks like:
- Loading 16-bit values
- Rotating values
- Performing arithmetic

#### Example Macro

```asm
.macro ROTATE_LEFT
    lsl \regA       ; Multiply A by 2
    rol \regB       ; Rotate B left through carry
.endmacro
```

---

## 🎨 Visual Aids

All core components are illustrated using **Mermaid diagrams** for clarity.

---

## 🛠 Project Setup & Requirements

- **Microcontroller:** ATmega328P (e.g., Arduino Uno)
- **Power Supply:** 5V regulated
- **Compiler/IDE:** AVR Studio (Atmel/Microchip)
- **Simulator:** Proteus Design Suite (load `.hex`, not source)

---

## 🚧 Limitations

- ⚠ Not portable to other architectures without rewrite
- 🔒 Not hardened for production-grade environments
- 🧱 Fixed configuration (rounds and key size are compile-time)

---

## 🧠 Future Improvements

- [ ] Add runtime configurability for rounds/key size
- [ ] Implement constant-time operations for side-channel resistance
- [ ] Add UART interface for real-time output
- [ ] Create macro library for reusable crypto functions

---

## 🤝 Contributing

Contributions are welcome! If you'd like to improve documentation, enhance security, or add features, feel free to open a PR or issue.

---

## 📜 License

MIT License – see [LICENSE](LICENSE)

---

## 📚 References

- Ronald Rivest, “The RC5 Encryption Algorithm”
- Atmel ATmega328P Datasheet
- AVR Instruction Set Manual

---

## 💬 Author

👤 **Mariam Wael Elkholey**  
📧 Mariam.wael.elkholey@gmail.com 
📍 Alexandria, Egypt



