# Dockerfile para Auth-API (PHP)
FROM php:8.2-apache

# 1. Instala dependências do sistema
RUN apt-get update && apt-get install -y \
    libpq-dev \
    git \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

# 2. Instala extensões PHP necessárias
RUN docker-php-ext-install pdo pdo_pgsql

# 3. Instala o Composer (opcional, se seu projeto usar)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4. Configura o Apache
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 5. Habilita mod_rewrite
RUN a2enmod rewrite

# 6. Copia os arquivos da aplicação
COPY . /var/www/html/

# 7. Define permissões (ajuste conforme sua estrutura de diretórios)
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \;

# 8. Diretório de trabalho
WORKDIR /var/www/html

# 9. Porta exposta
EXPOSE 80

# 10. Comando de inicialização
CMD ["apache2-foreground"]