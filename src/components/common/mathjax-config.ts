/* eslint-disable @typescript-eslint/no-unused-vars, @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call */

interface Window {
	MathJax: any
}

window.MathJax = {
	tex: {
		packages: { '[+]': ['noerrors'] }
	},
	loader: {
		paths: {
			mathjax: `${process.env.VUE_ROUTER_BASE ?? ''}mathjax`
		},
		load: ['input/asciimath', '[tex]/noerrors']
	},
	startup: {
		ready: () => {
			const AM = window.MathJax.InputJax.AsciiMath.AM;
			for (let i = 0; i < AM.symbols.length; ++i) {
				if (AM.symbols[i].input == '**') {
					AM.symbols[i] = { input: '**', tag: 'msup', output: '^', tex: null, ttype: AM.TOKEN.INFIX };
				}
			}
			return window.MathJax.startup.defaultReady();
		}
	},
	options: {
		renderActions: {
			findScript: [10, (doc: any) => {
				document.querySelectorAll('script[type^="math/tex"]').forEach((node: Element) => {
					const display = !!/; *mode=display/.exec((node as HTMLScriptElement).type);
					const math = new doc.options.MathItem(node.textContent, doc.inputJax[0], display);
					const text = document.createTextNode('');
					node.parentNode?.replaceChild(text, node);
					math.start = { node: text, delim: '', n: 0 };
					math.end = { node: text, delim: '', n: 0 };
					doc.math.push(math);
				});
			}, '']
		},
		ignoreHtmlClass: 'tex2jax_ignore'
	}

};
