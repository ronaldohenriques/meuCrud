import {Component} from '@angular/core';
import {CommonModule} from '@angular/common';
import {RouterModule} from '@angular/router';
import {MatListModule} from '@angular/material/list';
import {MatExpansionModule} from '@angular/material/expansion';
import {MatIconModule} from '@angular/material/icon';
import {MatButtonModule} from '@angular/material/button';

export interface MenuItem {
  label: string;
  icon: string;
  routerLink?: string;
  items?: MenuItem[];
}

@Component({
  selector: 'app-sidebar',
  imports: [
    CommonModule,
    RouterModule,
    MatListModule,
    MatExpansionModule,
    MatIconModule,
    MatButtonModule
  ],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.css'
})
export class SidebarComponent {
  items: MenuItem[] = [
    {
      label: 'Cadastros',
      icon: 'books',
      items: [
        {label: 'Contatos', icon: 'people', routerLink: '/contatos'},
        {label: 'Categorias', icon: 'local_offer', routerLink: '/categorias'}
      ]
    }
  ];
}
