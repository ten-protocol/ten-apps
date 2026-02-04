# Technology Stack

**Analysis Date:** 2026-02-04

## Languages

**Primary:**
- TypeScript 4.9.4 - Video generation components and UI
- Go 1.25.4 - Backup/recovery tools and utilities

**Secondary:**
- YAML - Kubernetes/ArgoCD configuration
- JavaScript - Build and configuration scripts

## Runtime

**Environment:**
- Node.js (npm 10.9.3)
- Go 1.25.4

**Package Manager:**
- npm 10.9.3
- Lockfile: not detected in main directories

## Frameworks

**Core:**
- Remotion 4.0.0 - Video generation and rendering framework
- React 18.0.0 - UI components for video scenes

**Testing:**
- Not detected

**Build/Dev:**
- TypeScript 4.9.4 - Type checking and compilation
- ESLint 8.43.0 - Code linting
- Prettier 2.8.8 - Code formatting

## Key Dependencies

**Critical:**
- @remotion/cli 4.0.0 - Video rendering command-line interface
- github.com/ethereum/go-ethereum v1.16.8 - Ethereum blockchain interaction for backup tools

**Infrastructure:**
- @remotion/lottie 4.0.0 - Lottie animation support
- @remotion/shapes 4.0.0 - Shape drawing utilities
- @remotion/transitions 4.0.0 - Video transition effects

## Configuration

**Environment:**
- TypeScript config at `ten-network-backup-video/tsconfig.json`
- Remotion config at `ten-network-backup-video/remotion.config.ts`
- Go modules at `scripts/go.mod`

**Build:**
- Target: ES2017
- JSX: react-jsx
- Video format: JPEG with yuv420p pixel format
- CRF: 18 (quality setting)

## Platform Requirements

**Development:**
- Node.js with npm 10.9.3+
- Go 1.25.4+
- TypeScript 4.9.4+

**Production:**
- Kubernetes cluster (ArgoCD-managed deployments)
- Helm 3.x for chart management

---

*Stack analysis: 2026-02-04*