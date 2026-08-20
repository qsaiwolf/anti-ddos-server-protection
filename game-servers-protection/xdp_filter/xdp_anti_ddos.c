#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/in.h>
#include <linux/udp.h>
#include <bpf/bpf_helpers.h>

// This XDP program provides high-performance DDoS mitigation at the NIC level.
// It specifically targets common UDP amplification floods and fragmented attacks.

#ifndef __constant_htons
#define __constant_htons(x) __builtin_bswap16(x)
#endif
#ifndef __constant_ntohs
#define __constant_ntohs(x) __builtin_bswap16(x)
#endif

SEC("xdp")
int xdp_prog(struct xdp_md *ctx) {
    void *data_end = (void *)(long)ctx->data_end;
    void *data = (void *)(long)ctx->data;
    
    struct ethhdr *eth = data;
    if (data + sizeof(struct ethhdr) > data_end)
        return XDP_PASS;

    // Only inspect IPv4
    if (eth->h_proto != __constant_htons(ETH_P_IP))
        return XDP_PASS;

    struct iphdr *ip = data + sizeof(struct ethhdr);
    if ((void *)(ip + 1) > data_end)
        return XDP_PASS;

    // 1. Drop fragmented IP packets. 
    // Legitimate game traffic rarely fragments. Amplification attacks (NTP, DNS, Memcached) rely heavily on fragmentation.
    if (ip->frag_off & __constant_htons(IP_MF | IP_OFFSET)) {
        return XDP_DROP;
    }

    // Only apply further rules to UDP (Games use UDP)
    if (ip->protocol != IPPROTO_UDP)
        return XDP_PASS;

    struct udphdr *udp = (void *)ip + (ip->ihl * 4);
    if ((void *)(udp + 1) > data_end)
        return XDP_PASS;

    // 2. Drop large UDP packets
    // Most legitimate game server traffic (CSGO, Rust, Minecraft UDP queries) is small (< 1000 bytes).
    // Amplification floods send massive 1400+ byte packets.
    if (__constant_ntohs(ip->tot_len) > 1200) {
        return XDP_DROP;
    }

    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
