import {Component} from '@angular/core';
import {MatToolbarModule} from '@angular/material/toolbar';
import {MatButtonModule} from '@angular/material/button';
import {MatMenuModule} from '@angular/material/menu';
import {MatIconModule} from '@angular/material/icon';
import {RouterModule} from '@angular/router';
import {CommonModule} from '@angular/common';

export interface MenuItem {
  label: string;
  icon: string;
  routerLink: string;
}

@Component({
  selector: 'app-topbar',
  imports: [
    CommonModule,
    MatToolbarModule,
    MatButtonModule,
    MatMenuModule,
    MatIconModule,
    RouterModule
  ],
  templateUrl: './topbar.component.html',
  styleUrl: './topbar.component.css'
})
export class TopbarComponent {
  items: MenuItem[] = [
    {label: 'Home', icon: 'home', routerLink: '/'},
    {label: 'Ajuda', icon: 'help', routerLink: '/ajuda'}
  ];
}
