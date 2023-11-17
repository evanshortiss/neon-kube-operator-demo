import { PrismaClient } from '@prisma/client';
import { get } from 'env-var'
import { PHASE_PRODUCTION_BUILD } from 'next/constants';
const globalForPrisma = global as unknown as { prisma: PrismaClient };

const NODE_ENV = get('NODE_ENV').default('development').asEnum(['development', 'production'])
const NEXT_PHASE = get('NEXT_PHASE').asString()

const isProductionEnv = NODE_ENV === 'production'
const isBuildingProduction = NEXT_PHASE === PHASE_PRODUCTION_BUILD

// This will throw an error if the environment variables are missing at runtime,
// but will not throw when compiling a production build using next
const DATABASE_HOSTNAME = get('DATABASE_HOSTNAME').required(isProductionEnv && !isBuildingProduction).asString()
const DATABASE_PASSWORD = get('DATABASE_PASSWORD').required(isProductionEnv && !isBuildingProduction).asString()
const DATABASE_USERNAME = get('DATABASE_USERNAME').required(isProductionEnv && !isBuildingProduction).asString()

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    datasources: {
      db: {
        // when using a pooled database connection with prisma, you need to append`?pgbouncer=true` to the connection string.
        // The reason this is done here rather than in the .env file is because the Neon Vercel integration doesn't include it.
        url: `postresql://${DATABASE_USERNAME}:${DATABASE_PASSWORD}@${DATABASE_HOSTNAME}?pgbouncer=true&connect_timeout=10&pool_timeout=10`,
      },
    },
  });

if (isProductionEnv) globalForPrisma.prisma = prisma;
