# Coding Conventions

**Analysis Date:** 2026-02-04

## Naming Patterns

**Files:**
- PascalCase for React components: `TenNetworkBackupVideo.tsx`, `Introduction.tsx`, `KeyCeremony.tsx`
- camelCase for modules/utilities: `remotion.config.ts`
- kebab-case for scripts: `decrypt-backup.go`, `test-backup-restore.sh`, `generate-keys.sh`
- snake_case for Go modules: `test_backup_key_private.pem`

**Functions:**
- camelCase for TypeScript/React: `useCurrentFrame()`, `useVideoConfig()`
- camelCase for Go functions: `readPrivateKeyFromPEM()`, `main()`

**Variables:**
- camelCase for TypeScript: `titleText`, `titleColor`, `encryptedHex`, `privKeyBytes`
- snake_case for shell scripts: `TEST_KEY_NAME`, `KEYS_DIR`, `COMPRESSED_PUBLIC_KEY`

**Types:**
- PascalCase for interfaces: `TenNetworkBackupVideoProps`, `IntroductionProps`

## Code Style

**Formatting:**
- Prettier 2.8.8 configured
- No explicit Prettier config file - using defaults

**Linting:**
- ESLint 8.43.0 configured
- No explicit ESLint config file detected

## Import Organization

**Order:**
1. External libraries: `import {AbsoluteFill, Sequence} from 'remotion'`
2. Local components: `import {Introduction} from './scenes/Introduction'`
3. Types/interfaces (inline with usage)

**Path Aliases:**
- Relative imports used: `'./scenes/Introduction'`, `'./Root'`

## Error Handling

**Patterns:**
- Go uses explicit error returns: `readPrivateKeyFromPEM(pemPath string) ([]byte, error)`
- Shell scripts use `set -e` for fail-fast behavior
- TypeScript/React uses try-catch implicitly through framework

## Logging

**Framework:** console (implicit in React/Remotion)

**Patterns:**
- Go uses `fmt.Printf` for structured output with color coding
- Shell scripts use colored output with `echo -e` and escape sequences
- TypeScript components use declarative props for state

## Comments

**When to Comment:**
- Function documentation in Go: detailed parameter explanations
- Complex animations: `/* Scene timing comments */`
- Shell script sections: `# Step 1: Generate test keys`

**JSDoc/TSDoc:**
- Not systematically used in TypeScript components
- Interface props are self-documenting

## Function Design

**Size:** Functions are focused and single-purpose

**Parameters:**
- TypeScript uses interface props: `TenNetworkBackupVideoProps`
- Go uses explicit parameter types: `(pemPath string, encryptedHex string)`

**Return Values:**
- Go uses explicit error handling: `([]byte, error)`
- TypeScript uses JSX return type

## Module Design

**Exports:**
- Named exports for components: `export const Introduction`
- Default exports not used

**Barrel Files:**
- Not used - direct imports preferred

---

*Convention analysis: 2026-02-04*