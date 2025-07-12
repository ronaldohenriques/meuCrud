// main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';

bootstrapApplication(AppComponent, appConfig)
  .catch((err) => {
    // Loga o erro crítico no console do navegador para depuração imediata em desenvolvimento.
    // Inclui o trace para facilitar a localização do problema.
    console.error('Erro crítico na inicialização da aplicação em ambiente de desenvolvimento:', err);
    console.trace('Stack trace do erro de inicialização:', err);

    // Conteúdo HTML para exibir o erro ao usuário.
    // Usamos estilos inline básicos para garantir visibilidade mesmo sem CSS externo.
    const errorContent = `
        <div class="critical-error">
          <h1>Oops! Algo deu errado durante a inicialização.</h1>
          <p>Verifique o console do navegador (F12) para detalhes sobre o erro.</p>
          <p style="margin-top: 20px;">
            <strong>Detalhes do Erro:</strong>
            <pre class="error-details">${err.message || 'Erro desconhecido'}</pre>
          </p>
        </div>
      `;

    // Tenta usar o elemento raiz do Angular primeiro.
    const appRoot = document.querySelector('app-root');

    if (appRoot) {
      appRoot.innerHTML = errorContent;
      appRoot.classList.add('critical-error-mode'); // Adiciona classe para estilização adicional via CSS global
    }
    // Se o elemento raiz não existir (falha muito precoce no bootstrap), cria um novo container.
    else {
      const errorContainer = document.createElement('div');
      errorContainer.id = 'critical-error-container'; // ID para estilização via CSS global
      errorContainer.innerHTML = errorContent;
      document.body.prepend(errorContainer); // Adiciona no início do body
    }

    // Adiciona um bloco de estilo dinamicamente para garantir que a mensagem de erro seja visível.
    // Estes são estilos de "último recurso" e usam !important para sobrescrever qualquer coisa.
    const styleElement = document.createElement('style');
    styleElement.textContent = `
      /* Estilos para o modo de erro crítico - aplicados ao app-root ou ao container de erro */
      .critical-error-mode, #critical-error-container {
        display: block !important;
        visibility: visible !important;
        opacity: 1 !important;
        position: fixed !important; /* Usar fixed para garantir que fique sempre visível */
        top: 0;
        left: 0;
        width: 100vw !important; /* Ocupa a largura total da viewport */
        height: 100vh !important; /* Ocupa a altura total da viewport */
        padding: 20px;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; /* Fontes mais seguras */
        color: #d32f2f;
        background-color: #fff; /* Fundo branco para visibilidade */
        z-index: 99999; /* Garante que esteja acima de tudo */
        display: flex;
        align-items: center;
        justify-content: center;
      }

      /* Estilos para o conteúdo central do erro */
      .critical-error {
        text-align: center;
        max-width: 800px;
        margin: 0 auto;
        padding: 30px;
        border: 1px solid #ef9a9a; /* Borda suave */
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1); /* Sombra suave */
        background-color: #ffebee; /* Fundo claro para o box de erro */
      }

      /* Estilos para os detalhes do erro (preformatted text) */
      .error-details {
        white-space: pre-wrap; /* Quebra de linha para mensagens longas */
        text-align: left;
        background: #fdf6f6; /* Fundo para o bloco de detalhes */
        padding: 15px;
        border-radius: 4px;
        overflow-y: auto; /* Scroll se a mensagem for muito longa */
        max-height: 200px; /* Altura máxima para os detalhes */
        font-size: 0.9em;
        line-height: 1.4;
        color: #3f51b5; /* Cor para os detalhes, para diferenciar */
        border: 1px solid #c5cae9;
      }

      /* Estilos responsivos básicos */
      @media (max-width: 600px) {
        .critical-error {
          padding: 15px;
        }
        .error-details {
          font-size: 0.8em;
          padding: 10px;
        }
      }
    `;
    document.head.appendChild(styleElement); // Adiciona a folha de estilo ao head

  });