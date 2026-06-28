const ttlMs = Number(process.env.PASSWORD_RESET_THROTTLE_TTL_MS ?? 3_600_000);

export const forgotPasswordThrottle = {
  default: {
    limit: Number(process.env.PASSWORD_RESET_THROTTLE_LIMIT ?? 10),
    ttl: ttlMs,
  },
};

export const resetPasswordThrottle = {
  default: {
    limit: Number(process.env.PASSWORD_RESET_VERIFY_THROTTLE_LIMIT ?? 15),
    ttl: ttlMs,
  },
};
