# Audit Scope – `src/` Directory

This document defines which parts of the `src/` directory in the LTV Protocol codebase are **included in the security audit scope**.

## Folder Inclusion Table

| Folder             | Include in Audit? |
|--------------------|-------------------|
| connectors         | ✅ Yes            |
| dummy              | ❌ No             |
| elements           | ✅ Yes            |
| errors             | ✅ Yes            |
| events             | ✅ Yes            |
| facades            | ✅ Yes            |
| ghost              | ❌ No             |
| interfaces         | ✅ Yes            |
| math               | ✅ Yes            |
| modifiers          | ✅ Yes            |
| public             | ✅ Yes            |
| state_reader       | ✅ Yes            |
| state_transition   | ✅ Yes            |
| states             | ✅ Yes            |
| structs            | ✅ Yes            |
| timelock           | ❌ No             |
| utils              | ✅ Yes            |
| Constants.sol      | ✅ Yes            |
