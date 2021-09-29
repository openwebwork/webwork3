/* global MathJax */

(() => {
	let knowlUID = 0;

	// Open the knowl the first time (bootstrap handles the rest)
	const initialOpen = (knowl) => {
		knowl.dataset.bsTarget = '#' + knowl.knowlContainer.id;
		knowl.click();
	};

	// This sets the innerHTML of the element and executes any script tags therein.
	const setInnerHTML = (elt, html) => {
		elt.innerHTML = html;
		elt.querySelectorAll('script').forEach((origScript) => {
			const newScript = document.createElement('script');
			Array.from(origScript.attributes).forEach(attr => newScript.setAttribute(attr.name, attr.value));
			newScript.appendChild(document.createTextNode(origScript.innerHTML));
			origScript.parentNode.replaceChild(newScript, origScript);
		});
	};

	// Register a click handler for each element with the knowl attribute.
	// The handler function does the download/show/hide magic.
	const initializeKnowl = (knowl) => {
		knowl.dataset.bsToggle = 'collapse';
		knowl.href = '';
		knowl.addEventListener('click', async (evt) => {
			evt.preventDefault();
			if (!knowl.knowlContainer) {
				// The knowl attribute either contains the url link to the content that is to be displayed
				// or is empty for inline content.
				const knowlURL = knowl.getAttribute('knowl');

				knowl.knowlContainer = document.createElement('div');
				knowl.knowlContainer.id = 'knowl-uid-' + knowlUID++;
				knowl.knowlContainer.classList.add('collapse');
				const knowlOutput = document.createElement('div');
				knowlOutput.classList.add('knowl-output');
				const innerDiv = document.createElement('div');
				innerDiv.classList.add('knowl');
				const knowlContent = document.createElement('div');
				knowlContent.classList.add('knowl-content');
				const knowlFooter = document.createElement('div');
				knowlFooter.classList.add('knowl-footer');
				knowlFooter.textContent = knowlURL;
				innerDiv.append(knowlContent, knowlFooter);
				knowlOutput.appendChild(innerDiv);
				knowl.knowlContainer.appendChild(knowlOutput);

				// Set the knowl container display style to none while hidden to remove its contents from the tab order.
				knowl.knowlContainer.addEventListener('show',
					() => { knowl.knowlContainer.style.display = 'block'; knowl.classList.add('active'); });
				knowl.knowlContainer.addEventListener('hide', () => { knowl.classList.remove('active'); });
				knowl.knowlContainer.addEventListener('hidden', () => { knowl.knowlContainer.style.display = 'none'; });

				// If the knowl is inside a td or th in a table then insert a new row into the table to contain the
				// knowl content. Otherwise insert the content after the knowl.
				if (knowl.parentNode.tagName.toLowerCase() === 'td' || knowl.parentNode.tagName.toLowerCase() == 'th') {
					const row = document.createElement('tr');
					const td = document.createElement('td');
					td.colSpan = knowl.parentNode.parentNode.childElementCount;
					td.appendChild(knowl.knowlContainer);
					row.appendChild(td);
					knowl.parentNode.parentNode.after(row);
				} else {
					knowl.after(knowl.knowlContainer);
				}

				if (knowl.getAttribute('class') === 'internal') {
					// Inline html
					setInnerHTML(knowlContent, knowl.getAttribute('value'));
				} else {
					// Retrieve url content.
					const response = await fetch(knowlURL);
					const data = response.ok ? await response.text() : response;
					if (typeof data == 'object') {
						knowlContent.textContent = 'ERROR: ' + data.status + ' ' + data.statusText;
						knowlContent.classList.add('knowl-error');
					} else {
						setInnerHTML(knowlContent, data);
					}
				}

				// If we are using MathJax, then reveal the knowl after MathJax has finished rendering math content.
				if (window.MathJax == undefined) {
					initialOpen(knowl);
				}  else {
					MathJax.startup.promise =
						MathJax.startup.promise.then(() => MathJax.typesetPromise([knowlContent]));
					MathJax.startup.promise.then(() => initialOpen(knowl));
				}
			}
		});
	};

	// Deal with knowls that are already on the page.
	document.querySelectorAll('*[knowl]').forEach(initializeKnowl);

	// Deal with knowls that are added to the page later.
	const observer = new MutationObserver((mutationsList) => {
		mutationsList.forEach((mutation) => {
			mutation.addedNodes.forEach((node) => {
				if (node instanceof Element) {
					if (node.hasAttribute('knowl')) initializeKnowl(node);
					else node.querySelectorAll('*[knowl]').forEach(initializeKnowl);
				}
			});
		});
	});
	observer.observe(document.body, { childList: true, subtree: true });
})();
