const imagemin = require('imagemin');
const imageminWebp = require('imagemin-webp');

(async () => {
	await imagemin(['source/images/*/*.{jpg,png}'], {
		destination: 'source/images/',
		plugins: [
			imageminWebp({quality: 50})
		]
	});

	console.log('Images optimized');
})();