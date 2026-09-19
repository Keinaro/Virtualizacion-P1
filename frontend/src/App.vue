<script setup>
</script>

<template>
  <header class="barra">
    <h1>El Quetzal</h1>
    <nav>
      <RouterLink to="/dashboard">Dashboard</RouterLink>
      <RouterLink to="/inventario">Inventario</RouterLink>
      <RouterLink to="/pedidos">Pedidos</RouterLink>
    </nav>
  </header>

  <main class="contenido">
    <RouterView />
  </main>
</template>

<style>
:root {
  font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
  color: #1f2933;
}

body {
  margin: 0;
  background: #f5f7fa;
}

.barra {
  display: flex;
  align-items: center;
  gap: 2rem;
  padding: 1rem 1.5rem;
  background: #0f766e;
  color: #fff;
  flex-wrap: wrap;
}

.barra h1 {
  margin: 0;
  font-size: 1.25rem;
}

.barra nav {
  display: flex;
  gap: 1rem;
}

.barra a {
  color: #d1fae5;
  text-decoration: none;
}

.barra a.router-link-active {
  color: #fff;
  font-weight: 600;
}

.contenido {
  padding: 1.5rem;
  max-width: 1100px;
  margin: 0 auto;
}

table {
  width: 100%;
  border-collapse: collapse;
  background: #fff;
}

th, td {
  padding: 0.6rem 0.75rem;
  border-bottom: 1px solid #e4e7eb;
  text-align: left;
}

.error {
  padding: 0.75rem 1rem;
  background: #fee2e2;
  color: #991b1b;
  border-radius: 6px;
}

.cargando {
  color: #52606d;
}
</style>
