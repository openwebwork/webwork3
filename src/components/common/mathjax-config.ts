/* eslint-disable */

interface Window {
  MathJax: any
}

window.MathJax = {
	loader: {
		paths: {
			mathjax: 'https://cdn.jsdelivr.net/npm/mathjax@3/es5'
		}
	},
	options: {
		renderActions: {
			findScript: [10, function (doc: any) {
				document.querySelectorAll('script[type^="math/tex"]').forEach(function(node) {
					const nodeType = node.getAttribute('type');

					const display = nodeType && !!nodeType.match(/; *mode=display/);
					const math = new doc.options.MathItem(node.textContent, doc.inputJax[0], display);
					const text = document.createTextNode('');
					if (node.parentNode) {
						node.parentNode.replaceChild(text, node);
						math.start = {node: text, delim: '', n: 0};
						math.end = {node: text, delim: '', n: 0};
						doc.math.push(math);
					}
				});
			}, '']
		}
	}
	// tex: {
	// inlineMath: [
	// ['$', '$'],
	// ['\\(', '\\)']
	// ]
	// }
};
