/* Library interfaces */

import { parseNonNegInt } from './index';
import { Dictionary, generic, Model, ParseableModel } from './index';
import { SubmitButton } from 'src/typings/renderer';

export interface Discipline {
	id: number;
	name: string;
	official: boolean;
}

export interface LibrarySubject {
	id: number;
	name: string;
	official: boolean;
}
