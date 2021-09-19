// this should more than likely be redirected at the backend rather
// than the renderer, unless we're going to go with the JWE route
import axios from 'axios';

export async function fetchProblem(formData: FormData, url: string, overrides: {[k:string]: string}) {
	Object.keys(overrides).forEach((k)=>{
		formData.set(k, overrides[k]);
	});

	let value;
	try {
		const response = await axios.post(url, formData,
			{ headers: { 'Content-Type': 'multipart/form-data' } });

		value = (response.data as { renderedHTML: string }).renderedHTML;
	} catch(e) {
		return 'e';
	}

	return value;
}
