/**
 * Comprime y redimensiona una imagen en el lado del cliente usando Canvas.
 * @param file El archivo original a comprimir
 * @param maxWidth Ancho máximo permitido (px)
 * @param quality Calidad JPEG (0.0 a 1.0)
 * @returns Promesa con el nuevo File comprimido
 */
export const compressImage = (file: File, maxWidth = 1024, quality = 0.8): Promise<File> => {
    return new Promise((resolve, reject) => {
        // No comprimir si no es imagen o es un GIF animado
        if (!file.type.startsWith('image/') || file.type === 'image/gif') {
            return resolve(file);
        }

        const img = new Image();
        const url = URL.createObjectURL(file);
        
        img.onload = () => {
            URL.revokeObjectURL(url);

            let width = img.width;
            let height = img.height;

            if (width > maxWidth) {
                height = Math.round((height * maxWidth) / width);
                width = maxWidth;
            }

            const canvas = document.createElement('canvas');
            canvas.width = width;
            canvas.height = height;
            const ctx = canvas.getContext('2d');
            
            if (!ctx) {
                return resolve(file); // Fallback si no hay soporte de canvas
            }

            ctx.drawImage(img, 0, 0, width, height);

            canvas.toBlob(
                (blob) => {
                    if (!blob) {
                        return resolve(file);
                    }
                    
                    // Aseguramos mantener la extensión correcta (jpeg para compresión lossy)
                    const newFileName = file.name.replace(/\.[^/.]+$/, "") + ".jpg";
                    const newFile = new File([blob], newFileName, {
                        type: 'image/jpeg',
                        lastModified: Date.now(),
                    });
                    resolve(newFile);
                },
                'image/jpeg',
                quality
            );
        };
        
        img.onerror = (err) => {
            URL.revokeObjectURL(url);
            resolve(file); // Fallback silencioso en caso de error
        };
        
        img.src = url;
    });
};
