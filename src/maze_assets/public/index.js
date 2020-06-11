import maze from 'ic:canisters/maze';

maze.greet(window.prompt("Enter your name:")).then(greeting => {
  window.alert(greeting);
});
