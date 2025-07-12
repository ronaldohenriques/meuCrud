import {Routes} from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./componentes/layout/layout/layout.component')
        .then(m => m.LayoutComponent),
    children: [
      {
        path: '',
        loadComponent: () =>
          import('./componentes/paginas/home/home.component')
            .then(m => m.HomeComponent)
      },
      {
        path: 'contatos',
        loadComponent: () =>
          import('./componentes/paginas/contatos/contatos.component')
            .then(m => m.ContatosComponent)
      },
      {
        path: 'categorias',
        loadComponent: () =>
          import('./componentes/paginas/categorias/categorias.component')
            .then(m => m.CategoriasComponent)
      },
      {
        path: 'ajuda',
        loadComponent: () =>
          import('./componentes/paginas/ajuda/ajuda.component')
            .then(m => m.AjudaComponent)
      }
    ]
  }
];


