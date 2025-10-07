# Usar imagen oficial de Node.js Alpine (ligera)
FROM node:18-alpine

# Establecer directorio de trabajo
WORKDIR /app

# Copiar package.json y package-lock.json
COPY package*.json ./

# Instalar dependencias
RUN npm install --production

# Copiar el resto del código
COPY . .

# Exponer el puerto
EXPOSE 3000

# Variable de entorno
ENV PORT=3000

# Comando para ejecutar la aplicación
CMD ["node", "server.js"]