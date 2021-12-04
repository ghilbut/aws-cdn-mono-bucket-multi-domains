<template>
  <div id="app">
    <div id="nav">
      [ EV1X ] &nbsp;&nbsp;&nbsp;
      <a href="/">Home</a> |
      <router-link to="/"> X </router-link> |
      <a href="/y">Y</a> |
      <a href="/about">About</a>
    </div>
    <router-view/>
  </div>
</template>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
}

#nav {
  padding: 30px;
}

#nav a {
  font-weight: bold;
  color: #2c3e50;
}

#nav a.router-link-exact-active {
  color: #42b983;
}
</style>
