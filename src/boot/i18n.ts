import { boot } from 'quasar/wrappers';
import type { LocaleMessageDictionary, VueMessageType } from 'vue-i18n';
import { createI18n } from 'vue-i18n';

const i18n = createI18n({
	legacy: false,
	globalInjection: true,
	fallbackLocale: 'en-US'
});

export default boot(({ app }) => {
	// Set i18n instance on app
	app.use(i18n);

	// Load the fallback locale
	void setI18nLanguage('en-US');
});

export const setI18nLanguage = async (locale: string) => {
	const messages: unknown = await import(/* webpackChunkName: "locale-[request]" */ `src/locales/${locale}.yml`);
	i18n.global.setLocaleMessage(locale, (messages as { default: LocaleMessageDictionary<VueMessageType> }).default);
	i18n.global.locale.value = locale;
	document.querySelector('html')?.setAttribute('lang', locale);
};
