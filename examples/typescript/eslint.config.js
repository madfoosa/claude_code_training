// @ts-check
import js from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['node_modules/**', 'dist/**', 'coverage/**'] },
  js.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      // The kit's CLAUDE.md forbids silencing the checker to make a gate pass.
      // These make that attempt fail loudly rather than slip through review.
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unnecessary-condition': 'error',
      '@typescript-eslint/ban-ts-comment': 'error',
      'no-console': 'warn',
    },
  },
  {
    // The config file itself is not covered by tsconfig's type-aware program.
    files: ['eslint.config.js'],
    ...tseslint.configs.disableTypeChecked,
  },
);
