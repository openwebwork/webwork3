// Color answer input elements with the proper color based on whether they are correct or incorrect.

window.color_inputs = (correct, incorrect) => {
	for (const ansName of correct) {
		document.querySelectorAll(`input[name*=${ansName}]`).forEach((input) => input.classList.add('correct'));
	}

	for (const ansName of incorrect) {
		document.querySelectorAll(`input[name*=${ansName}]`).forEach((input) => input.classList.add('incorrect'));
	}
};
