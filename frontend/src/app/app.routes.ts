import {Routes} from '@angular/router';
import {HomePageComponent} from "./pages/home-page/home-page.component";
import {AddProductComponent} from "./pages/add-product/add-product.component";
import {CartComponent} from "./pages/cart/cart.component";
import {ProductDetailComponent} from "./pages/product-detail/product-detail.component";
import {AdminDashboardComponent} from "./pages/admin-dashboard/admin-dashboard.component";
import {SimpleLoginComponent} from "./pages/simple-login/simple-login.component";
import {EditProductComponent} from "./pages/edit-product/edit-product.component";
import {FavoritesComponent} from "./pages/favorites/favorites.component";
import {adminGuard} from "./guards/admin.guard";

export const routes: Routes = [
  {path: 'login', component: SimpleLoginComponent},
  {path: '', component: HomePageComponent},
  {path: 'admin', component: AdminDashboardComponent, canActivate: [adminGuard]},
  {path: 'add-product', component: AddProductComponent, canActivate: [adminGuard]},
  {path: 'edit-product/:id', component: EditProductComponent, canActivate: [adminGuard]},
  {path: 'cart', component: CartComponent},
  {path: 'favorites', component: FavoritesComponent},
  {path: 'product/:id', component: ProductDetailComponent}
];
