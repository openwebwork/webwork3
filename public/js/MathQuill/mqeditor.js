'use strict';

/* global MathQuill, $ */

// Global list of all MathQuill answer inputs.
var answerQuills = {};

(() => {
	// initialize MathQuill
	var MQ = MathQuill.getInterface(2);

	const setupMQInput = (mq_input) => {
		var answerLabel = mq_input.id.replace(/^MaThQuIlL_/, '');
		var input = $('#' + answerLabel);
		var inputType = input.attr('type');
		if (typeof(inputType) != 'string' || inputType.toLowerCase() !== 'text' || !input.hasClass('codeshard')) return;

		var answerQuill = $("<span id='mq-answer-" + answerLabel + "'></span>");
		answerQuill.input = input;
		input.addClass('mq-edit');
		answerQuill.latexInput = $(mq_input);

		input.after(answerQuill);

		// Default options.
		var cfgOptions = {
			spaceBehavesLikeTab: true,
			leftRightIntoCmdGoes: 'up',
			restrictMismatchedBrackets: true,
			sumStartsWithNEquals: true,
			supSubsRequireOperand: true,
			autoCommands: 'pi sqrt root vert inf union abs',
			rootsAreExponents: true,
			maxDepth: 10
		};

		// Merge options that are set by the problem.
		var optOverrides = answerQuill.latexInput.data('mq-opts');
		if (typeof(optOverrides) == 'object') $.extend(cfgOptions, optOverrides);

		// This is after the option merge to prevent handlers from being overridden.
		cfgOptions.handlers = {
			edit: function(mq) {
				if (mq.text() !== '') {
					answerQuill.input.val(mq.text().trim());
					answerQuill.latexInput
						.val(mq.latex().replace(/^(?:\\\s)*(.*?)(?:\\\s)*$/, '$1'));
				} else {
					answerQuill.input.val('');
					answerQuill.latexInput.val('');
				}
			},
			// Disable the toolbar when a text block is entered.
			textBlockEnter: function() {
				if (answerQuill.toolbar)
					answerQuill.toolbar.find('button').prop('disabled', true);
			},
			// Re-enable the toolbar when a text block is exited.
			textBlockExit: function() {
				if (answerQuill.toolbar)
					answerQuill.toolbar.find('button').prop('disabled', false);
			}
		};

		answerQuill.mathField = MQ.MathField(answerQuill[0], cfgOptions);

		answerQuill.textarea = answerQuill.find('textarea');

		answerQuill.hasFocus = false;

		answerQuill.buttons = [
			{ id: 'frac', latex: '/', tooltip: 'fraction (/)', icon: '\\frac{\\text{  }}{\\text{  }}' },
			{ id: 'abs', latex: '|', tooltip: 'absolute value (|)', icon: '|\\text{  }|' },
			{ id: 'sqrt', latex: '\\sqrt', tooltip: 'square root (sqrt)', icon: '\\sqrt{\\text{  }}' },
			{ id: 'nthroot', latex: '\\root', tooltip: 'nth root (root)', icon: '\\sqrt[\\text{  }]{\\text{  }}' },
			{ id: 'exponent', latex: '^', tooltip: 'exponent (^)', icon: '\\text{  }^\\text{  }' },
			{ id: 'infty', latex: '\\infty', tooltip: 'infinity (inf)', icon: '\\infty' },
			{ id: 'pi', latex: '\\pi', tooltip: 'pi (pi)', icon: '\\pi' },
			{ id: 'vert', latex: '\\vert', tooltip: 'such that (vert)', icon: '|' },
			{ id: 'cup', latex: '\\cup', tooltip: 'union (union)', icon: '\\cup' },
			// { id: 'leq', latex: '\\leq', tooltip: 'less than or equal (<=)', icon: '\\leq' },
			// { id: 'geq', latex: '\\geq', tooltip: 'greater than or equal (>=)', icon: '\\geq' },
			{ id: 'text', latex: '\\text', tooltip: 'text mode (")', icon: 'Tt' }
		];

		// Open the toolbar when the mathquill answer box gains focus.
		answerQuill.textarea.on('focusin', function() {
			answerQuill.hasFocus = true;
			if (answerQuill.toolbar) return;
			answerQuill.toolbar = $("<div class='quill-toolbar'>" +
				answerQuill.buttons.reduce(
					function(returnString, curButton) {
						return returnString +
							"<button id='" + curButton.id + '-' + answerQuill.attr('id') +
							"' class='symbol-button btn' " +
							"' data-latex='" + curButton.latex +
							"' data-toggle='tooltip' title='" + curButton.tooltip + "'>" +
							"<span id='icon-" + curButton.id + '-' + answerQuill.attr('id') + "'>"
							+ curButton.icon +
							'</span>' +
							'</button>';
					}, ''
				) + '</div>');
			answerQuill.toolbar.appendTo(document.body);

			answerQuill.toolbar.find('.symbol-button').each(function() {
				MQ.StaticMath($('#icon-' + this.id)[0]);
			});

			// There is a bug in bootstrap version 2.3.2 that makes the "placement: left" option fail for tooltips.
			// This ugly hackery fixes the position of the tooltip.
			//function positionTooltip(tooltip, element) {
			//  var $tooltip = $(tooltip);
			//  $tooltip.css('display', 'none');
			//  $tooltip.find('.tooltip-inner').css('display', 'none');
			//  var $element = $(element);
			//  setTimeout(() => {
			//    $tooltip.css('display', 'block');
			//    $tooltip.find('.tooltip-inner').css({ whiteSpace: 'nowrap', display: 'block' });
			//    $tooltip.addClass('left')
			//      .css({
			//        top: `${$element.position().top + ($element.outerHeight() - $tooltip.outerHeight()) / 2}px`,
			//        right: `${$element.outerWidth() + 2}px`,
			//        left: 'unset'
			//      });
			//    $tooltip.find('.tooltip-arrow').css({ left: 'unset' });
			//    $tooltip.addClass('in');
			//  }, 0);
			//}

			//$('.symbol-button[data-toggle="tooltip"]').tooltip({
			//  trigger: 'hover', placement: positionTooltip, delay: { show: 500, hide: 0 }
			//});

			$('.symbol-button').on('click', function() {
				answerQuill.hasFocus = true;
				answerQuill.mathField.cmd(this.getAttribute('data-latex'));
				answerQuill.textarea.focus();
			});
		});

		answerQuill.textarea.on('focusout', function() {
			answerQuill.hasFocus = false;
			setTimeout(function() {
				if (!answerQuill.hasFocus && answerQuill.toolbar)
				{
					answerQuill.toolbar.remove();
					delete answerQuill.toolbar;
				}
			}, 200);
		});

		// Trigger an answer preview when the enter key is pressed in an answer box.
		answerQuill.on('keypress.preview', function(e) {
			if (e.key == 'Enter' || e.which == 13 || e.keyCode == 13) {
				// For homework
				$('#previewAnswers_id').trigger('click');
				// For gateway quizzes
				$('input[name=previewAnswers]').trigger('click');
			}
		});

		answerQuill.mathField.latex(answerQuill.latexInput.val());
		answerQuill.mathField.moveToLeftEnd();
		answerQuill.mathField.blur();

		// Give the mathquill answer box the correct/incorrect colors.
		setTimeout(function() {
			if (answerQuill.input.hasClass('correct')) answerQuill.addClass('correct');
			else if (answerQuill.input.hasClass('incorrect')) answerQuill.addClass('incorrect');
		}, 300);

		// Replace the result table correct/incorrect javascript that gives focus
		// to the original input, with javascript that gives focus to the mathquill
		// answer box.
		var resultsTableRows = $('table.attemptResults tr:not(:first-child)');
		if (resultsTableRows.length) {
			resultsTableRows.each(function() {
				var result = $(this).find('td > a');
				var href = result.attr('href');
				if (result.length && href !== undefined && href.indexOf(answerLabel) != -1) {
					// Set focus to the mathquill answer box if the correct/incorrect link is clicked.
					result.attr('href',
						"javascript:void(window.answerQuills['" + answerLabel + "'].textarea.focus())");
				}
			}
			);
		}

		answerQuills[answerLabel] = answerQuill;
	};

	// Observer that sets up MathQuill inputs.
	const observer = new MutationObserver((mutationsList) => {
		mutationsList.forEach((mutation) => {
			mutation.addedNodes.forEach((node) => {
				if (node.id && node.id.startsWith('MaThQuIlL_')) {
					setupMQInput(node);
				} else if (node.querySelectorAll) {
					node.querySelectorAll('input[id^=MaThQuIlL_]').forEach((input) => {
						setupMQInput(input);
					});
				}
			});
		});
	});
	observer.observe($('body')[0], { childList: true, subtree: true });

	// Stop the mutation observer when the window is closed.
	window.addEventListener('unload', function() { observer.disconnect(); });

})();
