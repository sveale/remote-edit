/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let Dialog;
const {$, $$, View, TextEditorView} = require('atom-space-pen-views');
const {CompositeDisposable} = require('atom');

module.exports =
  (Dialog = class Dialog extends View {
    static content(param) {
      if (param == null) { param = {}; }
      const {prompt} = param;
      return this.div({class: 'dialog'}, () => {
        this.label(prompt, {class: 'icon', outlet: 'promptText'});
        this.subview('miniEditor', new TextEditorView({mini: true}));
        return this.div({class: 'error-message', outlet: 'errorMessage'});
      });
    }

    initialize(param) {
      if (param == null) { param = {}; }
      const {iconClass} = param;
      if (iconClass) { this.promptText.addClass(iconClass); }

      this.disposables = new CompositeDisposable;
      this.disposables.add(atom.commands.add('atom-workspace', {
        'core:confirm': () => this.onConfirm(this.miniEditor.getText()),
        'core:cancel': event => {
          this.cancel();
          return event.stopPropagation();
        }
      }
      )
      );

      this.miniEditor.getModel().onDidChange(() => this.showError());
      return this.miniEditor.on('blur', () => this.cancel());
    }

    onConfirm(value) {
      if (typeof this.callback === 'function') {
        this.callback(undefined, value);
      }
      this.cancel();
      return value;
    }

    showError(message) {
      if (message == null) { message = ''; }
      this.errorMessage.text(message);
      if (message) { return this.flashError(); }
    }

    destroy() {
      return this.disposables.dispose();
    }

    cancel() {
      this.cancelled();
      this.restoreFocus();
      return this.destroy();
    }

    cancelled() {
      return this.hide();
    }

    toggle(callback) {
      this.callback = callback;
      if ((this.panel != null ? this.panel.isVisible() : undefined)) {
        return this.cancel();
      } else {
        return this.show();
      }
    }

    show() {
      if (this.panel == null) { this.panel = atom.workspace.addModalPanel({item: this}); }
      this.panel.show();
      this.storeFocusedElement();
      return this.miniEditor.focus();
    }

    hide() {
      return (this.panel != null ? this.panel.hide() : undefined);
    }

    storeFocusedElement() {
      return this.previouslyFocusedElement = $(document.activeElement);
    }

    restoreFocus() {
      return (this.previouslyFocusedElement != null ? this.previouslyFocusedElement.focus() : undefined);
    }
  });
