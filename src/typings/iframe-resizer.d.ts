import { IFrameObject } from 'iframe-resizer';

interface ExtendedIFrameObject extends IFrameObject {
    removeListeners(): void;
}

export interface ExtendedIFrameComponent extends HTMLIFrameElement {
    iFrameResizer: ExtendedIFrameObject;
}
