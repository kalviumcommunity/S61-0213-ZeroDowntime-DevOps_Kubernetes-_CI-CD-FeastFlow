# Frontend Directory

The Next.js application is located in the `app` subdirectory.

## Quick Start

```bash
cd app
npm install
npm run dev
```

The frontend will run on http://localhost:3000

## Important Directories

- `app/` - Next.js application (main frontend code)
  - `src/` - Source code
    - `app/` - Next.js app router pages
    - `components/` - React components
    - `context/` - React context providers
    - `types/` - TypeScript type definitions
  - `public/` - Static assets
  - `package.json` - Dependencies

## Environment Configuration

Make sure `app/.env.local` exists with:

```
NEXT_PUBLIC_API_URL=http://localhost:5000/api
```

## Available Scripts

(Run these from the `app` directory)

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint

## Pages

- `/` - Home page with restaurants
- `/login` - Login page
- `/signup` - Signup page
- `/test-auth` - Authentication test dashboard
- `/admin` - Admin dashboard
- `/restaurant/[id]` - Restaurant detail page

## Testing Authentication

After starting the dev server:

1. Visit http://localhost:3000/test-auth
2. Test the authentication flow
3. Or go to /login or /signup directly

Default admin credentials:

- Email: admin@feastflow.com
- Password: Admin@123
