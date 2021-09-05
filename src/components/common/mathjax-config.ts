
// eslint-disable-next-line @typescript-eslint/no-unused-vars
interface Window {
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
  MathJax: any
}

window.MathJax = {
	loader: {
		paths: {
			mathjax: 'https://cdn.jsdelivr.net/npm/mathjax@3/es5'
		}
	}
	// tex: {
	// inlineMath: [
	// ['$', '$'],
	// ['\\(', '\\)']
	// ]
	// }
};
